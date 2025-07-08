
WITH RecursiveMovieCast AS (
    SELECT 
        ci.movie_id,
        ka.name AS actor_name,
        ROW_NUMBER() OVER(PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order,
        COUNT(*) OVER(PARTITION BY ci.movie_id) AS total_actors
    FROM 
        cast_info ci
    JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    WHERE 
        ka.name IS NOT NULL
), 
RecentMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year,
        (SELECT COUNT(*) 
         FROM movie_companies mc 
         WHERE mc.movie_id = m.id AND mc.company_type_id IS NOT NULL) AS num_companies
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2020
      AND m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
),
AggregatedInfo AS (
    SELECT 
        rm.movie_id,
        COUNT(DISTINCT ka.person_id) AS distinct_actors,
        MAX(rm.total_actors) AS year_of_release
    FROM 
        RecursiveMovieCast rm
    LEFT JOIN 
        aka_name ka ON rm.actor_name = ka.name
    GROUP BY 
        rm.movie_id
)
SELECT 
    mm.title,
    mm.production_year,
    ai.distinct_actors,
    ai.year_of_release,
    CASE 
        WHEN ai.distinct_actors > 5 THEN 'Large Cast'
        ELSE 'Small or Medium Cast'
    END AS cast_size_category
FROM 
    RecentMovies mm
LEFT JOIN 
    AggregatedInfo ai ON mm.movie_id = ai.movie_id
WHERE 
    ai.distinct_actors IS NOT NULL
  AND mm.num_companies > 2
ORDER BY 
    ai.year_of_release DESC, 
    ai.distinct_actors DESC
LIMIT 10;
