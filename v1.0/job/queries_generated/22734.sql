WITH RECURSIVE MovieCTE AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title,
        t.production_year,
        COALESCE(CAST(SUM(ci.nr_order) OVER (PARTITION BY t.id), INTEGER), 0) AS total_cast,
        COALESCE(mo.info, 'N/A') AS movie_info,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        movie_info mo ON mo.movie_id = t.id AND mo.info_type_id = 1
    WHERE 
        t.production_year IS NOT NULL
),
ActorCTE AS (
    SELECT 
        ak.person_id, 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_played_in,
        AVG(m.prod_year) AS avg_production_year
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ci.person_id = ak.person_id
    LEFT JOIN 
        (SELECT 
            movie_id,
            MAX(production_year) AS prod_year 
         FROM 
            aka_title 
         GROUP BY 
            movie_id) m ON m.movie_id = ci.movie_id
    GROUP BY 
        ak.person_id, ak.name
),
YearlyStatistics AS (
    SELECT 
        production_year,
        COUNT(DISTINCT movie_id) AS movies_released,
        COUNT(DISTINCT actor_name) AS unique_actors
    FROM 
        MovieCTE m
    JOIN 
        ActorCTE a ON a.movies_played_in > 5
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        production_year
)
SELECT 
    mv.movie_title,
    a.actor_name,
    mv.total_cast,
    a.movies_played_in,
    ROUND(a.avg_production_year, 2) AS avg_actor_years,
    CASE 
        WHEN mv.total_cast > 10 THEN 'Large Cast'
        WHEN mv.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    YEAR(CURRENT_DATE) - mv.production_year AS years_since_release
FROM 
    MovieCTE mv
JOIN 
    ActorCTE a ON a.movies_played_in > 5
WHERE 
    mv.rn = 1
    AND mv.production_year IS NOT NULL
ORDER BY 
    mv.production_year DESC, 
    a.movies_played_in DESC
FETCH FIRST 100 ROWS ONLY;

-- Additional checks for NULL logic and set operations
SELECT 
    ak.name,
    COALESCE(NULLIF(m.title, ''), 'Unknown Title') AS movie_title
FROM 
    aka_name ak
LEFT JOIN 
    aka_title m ON m.id = ak.person_id
WHERE 
    ak.name IS NOT NULL
    AND m.production_year IS NOT NULL
UNION ALL
SELECT 
    ak.name,
    'Data Not Found' AS movie_title
FROM 
    aka_name ak
WHERE 
    ak.person_id NOT IN (SELECT DISTINCT cast_info.person_id FROM cast_info);
