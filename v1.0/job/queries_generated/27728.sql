WITH actor_movie_info AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        r.role AS actor_role
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
),
movie_statistics AS (
    SELECT 
        am.movie_id,
        am.movie_title,
        am.production_year,
        COUNT(distinct am.actor_id) AS total_actors,
        STRING_AGG(am.actor_name, ', ') AS actor_list
    FROM 
        actor_movie_info am
    GROUP BY 
        am.movie_id, am.movie_title, am.production_year
),
keyword_info AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        title m ON mk.movie_id = m.id
    GROUP BY 
        m.id
)
SELECT 
    ms.movie_id,
    ms.movie_title,
    ms.production_year,
    ms.total_actors,
    ms.actor_list,
    ki.keywords
FROM 
    movie_statistics ms
LEFT JOIN 
    keyword_info ki ON ms.movie_id = ki.movie_id
ORDER BY 
    ms.total_actors DESC, ms.production_year DESC;

This query is structured in several Common Table Expressions (CTEs) to generate an overview of actors in movies, their respective roles, and associated keywords. It calculates the total number of distinct actors per movie, concatenates their names into a list, and retrieves associated keywords for each movie, ordered by the number of actors and production year.
