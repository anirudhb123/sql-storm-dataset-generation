
WITH RECURSIVE ActorHierarchy AS (
    
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    GROUP BY ci.person_id
),

PopularMovies AS (
    
    SELECT
        cc.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM complete_cast cc
    JOIN cast_info ci ON cc.subject_id = ci.person_id
    JOIN aka_title at ON ci.movie_id = at.movie_id
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY cc.movie_id
    HAVING COUNT(DISTINCT ci.person_id) > 5
)

SELECT 
    an.name AS actor_name,
    COUNT(DISTINCT pm.movie_id) AS movies_with_multiple_actors,
    MAX(tt.production_year) AS most_recent_movie_year,
    STRING_AGG(DISTINCT at.title, ', ') AS movies_titles,
    SUM(pm.actor_count) AS total_actors_in_popular_movies
FROM aka_name an
JOIN cast_info ci ON an.person_id = ci.person_id
JOIN PopularMovies pm ON ci.movie_id = pm.movie_id
LEFT JOIN aka_title at ON ci.movie_id = at.movie_id
LEFT JOIN title tt ON tt.id = at.movie_id
WHERE tt.production_year IS NOT NULL
    AND tt.production_year > (SELECT AVG(production_year) FROM title)
GROUP BY an.name
HAVING COUNT(DISTINCT pm.movie_id) > 3
ORDER BY movies_with_multiple_actors DESC, most_recent_movie_year DESC;
