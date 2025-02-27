WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
), TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
), MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        mk.keyword,
        ci.kind AS company_kind
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        company_type ci ON mc.company_type_id = ci.id
)
SELECT 
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count,
    CASE 
        WHEN COUNT(DISTINCT mc.company_id) = 0 THEN 'No Companies'
        ELSE 'Companies Listed'
    END AS company_info
FROM 
    MovieDetails md
LEFT JOIN 
    movie_companies mc ON md.movie_id = mc.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year
HAVING 
    MAX(md.production_year) >= 2000
ORDER BY 
    md.production_year DESC, md.title;
