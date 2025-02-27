WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT
        mt.linked_movie_id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    WHERE
        mh.level < 3
),
ActorRoles AS (
    SELECT
        ci.person_id,
        r.role AS role_name,
        COUNT(*) AS movies_count
    FROM
        cast_info ci
    JOIN
        role_type r ON ci.role_id = r.id
    GROUP BY
        ci.person_id, r.role
),
TopActors AS (
    SELECT
        ar.person_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ar.role_name ORDER BY ar.movies_count DESC) AS rank
    FROM
        ActorRoles ar
    JOIN
        aka_name ak ON ar.person_id = ak.person_id
    WHERE
        ak.name IS NOT NULL
)
SELECT
    mh.movie_title,
    mh.production_year,
    STRING_AGG(DISTINCT ta.actor_name, ', ') AS top_actors,
    COUNT(DISTINCT mh.movie_id) OVER (PARTITION BY mh.production_year) AS total_movies,
    AVG(mk.count) AS avg_keywords
FROM
    MovieHierarchy mh
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    TopActors ta ON ta.role_name = 'Actor' AND LOOKUP(ta.movie_id) = mh.movie_id /* Hypothetical function */
WHERE
    mh.production_year IS NOT NULL
GROUP BY
    mh.movie_title,
    mh.production_year
HAVING
    COUNT(DISTINCT mh.movie_id) > 1 /* Ensuring at least 2 movies */
ORDER BY
    mh.production_year DESC, total_movies DESC;

### Explanation
1. **Recursive CTE (`MovieHierarchy`)**: This CTE constructs a hierarchy of movies starting from those released from the year 2000 onwards, exploring linked movies up to 3 levels deep.
  
2. **Actor Roles CTE (`ActorRoles`)**: This CTE aggregates actors' roles from the `cast_info` table, counting how many movies each actor has been in for each role.

3. **Top Actors CTE (`TopActors`)**: This CTE ranks actors by the number of movies they've done by role using a window function.

4. **Final Selection Statement**: The main query aggregates movie titles, their production years, and lists top actors for those movies, joining relevant data from previous CTEs. It uses `STRING_AGG` to concatenate actor names and computes the average number of keywords associated with each movie.

5. **Filtering and Ordering**: It ensures only movies with more than one related entry appear in results, ordering by their production year and count of distinct movies. 

This query is complex, employing multiple SQL constructs including recursive common table expressions (CTEs), window functions, and aggregation, to analyze movie data cohesively.
