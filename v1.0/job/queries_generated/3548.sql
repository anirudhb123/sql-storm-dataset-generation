WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rn <= 10
),
MoviesWithKeywords AS (
    SELECT 
        tm.title,
        string_agg(k.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.title
),
MovieInfoWithCompany AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(cn.name, 'Unknown') AS company_name, 
        co.kind AS company_type
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type co ON mc.company_type_id = co.id
)
SELECT 
    m.title,
    m.production_year,
    mk.keywords,
    CASE 
        WHEN m.production_year < 2000 THEN 'Classic'
        WHEN m.production_year >= 2000 AND m.production_year < 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    COUNT(DISTINCT ci.person_id) AS total_cast
FROM 
    MoviesWithKeywords mk
JOIN 
    MovieInfoWithCompany m ON mk.title = m.title
LEFT JOIN 
    cast_info ci ON m.title = ci.movie_id
GROUP BY 
    m.title, m.production_year, mk.keywords
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    m.production_year DESC, total_cast DESC;
