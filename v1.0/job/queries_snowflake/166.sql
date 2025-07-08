WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_per_year
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
), 
TopMovies AS (
    SELECT 
        r.title,
        r.production_year,
        r.cast_count
    FROM 
        RankedMovies r
    WHERE 
        r.rank_per_year <= 5
),
MovieDetails AS (
    SELECT 
        t.title,
        c.name AS company_name,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.title ORDER BY c.name) AS company_rank
    FROM 
        TopMovies tm
    JOIN 
        aka_title t ON tm.title = t.title AND tm.production_year = t.production_year
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    md.title,
    md.company_name,
    COALESCE(md.keyword, 'No Keyword') AS keyword_info
FROM 
    MovieDetails md
WHERE 
    md.company_rank <= 3
ORDER BY 
    md.title, md.company_name;
