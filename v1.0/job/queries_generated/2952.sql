WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn,
        COUNT(c.person_id) AS cast_count
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighCastMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        cast_count > (
            SELECT AVG(cast_count) 
            FROM RankedMovies
        )
),
MovieDetails AS (
    SELECT 
        h.title,
        h.production_year,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        COALESCE(cn.name, 'Unknown Company') AS company_name
    FROM 
        HighCastMovies h
    LEFT JOIN 
        movie_keyword mk ON h.title_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON h.title_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
)
SELECT 
    d.title,
    d.production_year,
    d.keyword,
    d.company_name,
    COUNT(DISTINCT p.id) AS actor_count,
    MAX(p.gender) AS predominant_gender
FROM 
    MovieDetails d
LEFT JOIN 
    cast_info c ON d.title_id = c.movie_id
LEFT JOIN 
    aka_name p ON c.person_id = p.person_id
GROUP BY 
    d.title, d.production_year, d.keyword, d.company_name
HAVING 
    MAX(p.gender) IS NOT NULL
ORDER BY 
    d.production_year DESC, actor_count DESC;
