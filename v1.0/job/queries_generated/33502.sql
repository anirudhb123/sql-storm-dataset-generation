WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(m.title AS VARCHAR(255)) AS full_title
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        mv.linked_movie_id,
        m.title,
        m.production_year,
        level + 1,
        CAST(mh.full_title || ' -> ' || m.title AS VARCHAR(255))
    FROM 
        movie_link mv
    JOIN 
        aka_title m ON mv.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mv.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
),
ActorMovieCount AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_title a ON c.movie_id = a.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        c.person_id
),
TopActors AS (
    SELECT 
        a.id AS actor_id,
        ak.name,
        ac.movie_count
    FROM 
        aka_name ak
    JOIN 
        ActorMovieCount ac ON ak.person_id = ac.person_id
    WHERE 
        ac.movie_count > 3
    ORDER BY 
        ac.movie_count DESC
    LIMIT 10
)
SELECT 
    mh.movie_id,
    mh.full_title,
    mh.level,
    ta.name AS top_actor_name,
    ta.movie_count AS actor_movie_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    TopActors ta ON mh.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ta.actor_id)
WHERE 
    mh.level = 1
ORDER BY 
    mh.production_year DESC, mh.full_title;

This query performs the following operations:

1. **Recursive CTE (`MovieHierarchy`)**: It builds a hierarchy of movies based on linked movies, allowing up to 5 levels of connections.
2. **Aggregate CTE (`ActorMovieCount`)**: It counts the number of movies each actor has appeared in since 2000.
3. **Top Actors CTE**: It identifies the top 10 actors who have appeared in more than 3 movies since 2000.
4. **Final selection**: Combines the movie hierarchy with the top actors to provide details about the movies and prominent actors associated with them, specifically only for the first movie level (root movies).

The results are ordered by the production year and movie title to categorize movie entries effectively.
