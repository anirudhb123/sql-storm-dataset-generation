WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 1990
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        m.production_year > 1990
),

ActorRankings AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        RANK() OVER (PARTITION BY ci.person_id ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        MovieHierarchy mh ON ci.movie_id = mh.movie_id
    GROUP BY 
        ci.person_id
),

FilteredActors AS (
    SELECT 
        ak.name AS actor_name, 
        ar.movies_count, 
        ar.actor_rank
    FROM 
        aka_name ak
    JOIN 
        ActorRankings ar ON ak.person_id = ar.person_id
    WHERE 
        ar.movies_count > 5
        AND ak.name IS NOT NULL
)

SELECT 
    title.title AS movie_title,
    title.production_year,
    string_agg(DISTINCT fa.actor_name, ', ') AS actors
FROM 
    aka_title title
LEFT JOIN 
    cast_info c ON title.id = c.movie_id
LEFT JOIN 
    FilteredActors fa ON c.person_id = fa.actor_name
GROUP BY 
    title.title, title.production_year
HAVING 
    COUNT(DISTINCT fa.actor_name) > 2
ORDER BY 
    title.production_year DESC, 
    title.title;

This query accomplishes several tasks:
1. It defines a recursive CTE (`MovieHierarchy`) to create a hierarchy of movies linked together by `movie_link`, filtering for movies released after 1990.
2. It calculates actor rankings based on the number of distinct movies they've acted in (`ActorRankings`) and filters for actors that have acted in more than 5 movies.
3. It filters actors with non-null names, joining their data to the `aka_title` table to compile the movie titles and production years.
4. Finally, it aggregates the actor names for each movie title, ensuring only titles with more than two distinct actors appear in the final output, which is ordered by production year and title.
