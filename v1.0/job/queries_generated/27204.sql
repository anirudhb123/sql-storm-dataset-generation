WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        STRING_AGG(DISTINCT aka.name, ', ') AS actors,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY mt.production_year DESC) AS movie_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name aka ON ci.person_id = aka.person_id
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023 
        AND ci.person_role_id IN (SELECT id FROM role_type WHERE role = 'Actor')
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        actors,
        keyword_count
    FROM 
        RankedMovies
    WHERE 
        movie_rank = 1
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.actors,
    CASE 
        WHEN tm.keyword_count > 10 THEN 'Highly Tagged'
        WHEN tm.keyword_count BETWEEN 5 AND 10 THEN 'Moderately Tagged'
        ELSE 'Less Tagged' 
    END AS tagging_category
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.keyword_count DESC;
