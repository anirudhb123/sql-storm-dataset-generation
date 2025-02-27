
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rn,
        COUNT(*) OVER (PARTITION BY a.production_year) AS total_movies
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        DISTINCT
        rm.title,
        rm.production_year,
        rm.total_movies
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        TopMovies tm
        JOIN title t ON t.title = tm.title AND t.production_year = tm.production_year
        LEFT JOIN movie_companies mc ON mc.movie_id = t.id
        LEFT JOIN company_name cn ON cn.id = mc.company_id
        LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
        LEFT JOIN keyword kc ON kc.id = mk.keyword_id
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.companies,
    md.keyword_count,
    COALESCE(md.keyword_count, 0) AS adjusted_keyword_count,
    CASE 
        WHEN md.keyword_count > 10 THEN 'High'
        WHEN md.keyword_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS keyword_category
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
