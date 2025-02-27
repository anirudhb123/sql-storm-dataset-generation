WITH Recursive ActorMovies AS (
    SELECT 
        ca.person_id,
        a.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY at.production_year DESC) AS movie_rank
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    JOIN 
        aka_title at ON ca.movie_id = at.movie_id
),

ActorsInSameYear AS (
    SELECT 
        am.actor_name,
        am.production_year,
        COUNT(DISTINCT am.person_id) AS co_actor_count
    FROM 
        ActorMovies am
    GROUP BY 
        am.actor_name, am.production_year
)

SELECT 
    a.actor_name,
    a.production_year,
    a.co_actor_count,
    CASE 
        WHEN a.co_actor_count > 5 THEN 'Super Cast'
        WHEN a.co_actor_count BETWEEN 3 AND 5 THEN 'Good Cast'
        ELSE 'Solo Act'
    END AS cast_quality,
    STRING_AGG(DISTINCT CONCAT('Co-star ID: ', am.person_id, ', Movie: ', am.movie_title) 
               ORDER BY am.movie_title DESC) AS co_stars_info
FROM 
    ActorsInSameYear a
LEFT JOIN 
    ActorMovies am ON a.actor_name = am.actor_name AND a.production_year = am.production_year
GROUP BY 
    a.actor_name, a.production_year, a.co_actor_count
HAVING 
    MAX(am.movie_rank) IS NULL OR COUNT(DISTINCT am.person_id) > 2
ORDER BY 
    a.production_year DESC, a.co_actor_count DESC
LIMIT 10;


In this elaborate query:

- **CTEs** (`WITH` clause) are used to first pull actor names along with their movies using `ROW_NUMBER()` to rank the movies by year.
- A secondary CTE counts co-actors for each actor in the same year to analyze collaborations.
- **CASE** statement categorizes cast quality based on the number of co-actors.
- The main SELECT clause aggregates information using `STRING_AGG()` to provide detailed co-star information, sorting the title in descending order.
- **LEFT JOINs** ensure that actors without any co-stars are also included in the output.
- **HAVING** clause introduces a filter for cases where a movie rank is null or where there are a significant number of co-actors.
- The query is ordered by production year and number of co-actors to show the most collaborative and newest acts in the results.
- **LIMIT** restricts the results to the top ten entries based on the order specified.
