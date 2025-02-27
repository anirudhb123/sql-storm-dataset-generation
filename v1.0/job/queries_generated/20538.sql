WITH RecursiveMovieCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(c.name, 'Unknown') AS company_name,
        COALESCE(aki.name, 'Unknown Actor') AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY aki.name) AS actor_order,
        COUNT(DISTINCT c.id) OVER (PARTITION BY m.id) AS company_count
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_companies AS mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name AS c ON c.id = mc.company_id
    LEFT JOIN 
        cast_info AS ci ON ci.movie_id = m.id
    LEFT JOIN 
        aka_name AS aki ON aki.person_id = ci.person_id
    WHERE 
        m.production_year IS NOT NULL 
        AND m.production_year NOT BETWEEN 1900 AND 2023
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        company_name,
        actor_name,
        actor_order,
        company_count,
        COUNT(*) OVER(PARTITION BY production_year) AS movies_per_year
    FROM 
        RecursiveMovieCTE
    WHERE 
        company_name IS NOT NULL
        AND actor_order <= 5
)

SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.company_name,
    f.actor_name,
    f.actor_order,
    f.company_count,
    f.movies_per_year,
    CASE 
        WHEN f.company_count = 0 THEN 'Indie Film'
        WHEN f.company_count > 5 THEN 'Blockbuster'
        ELSE 'Moderate Production'
    END AS production_type
FROM 
    FilteredMovies AS f
LEFT JOIN 
    (SELECT 
         production_year, 
         COUNT(DISTINCT movie_id) AS released_movies 
     FROM 
         RecursiveMovieCTE 
     GROUP BY 
         production_year
    ) AS yearly_movies 
ON 
    f.production_year = yearly_movies.production_year
ORDER BY 
    f.production_year DESC,
    f.company_count DESC,
    f.actor_order
LIMIT 1000;

-- Objective: To benchmark performance on handling complex JOINs, CTE usage, 
-- and processing conditional logic for result categorization.
