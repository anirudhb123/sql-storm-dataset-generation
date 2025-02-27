WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year > 2000  -- Consider movies produced after 2000

    UNION ALL

    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        h.level + 1
    FROM 
        MovieHierarchy h
    JOIN 
        movie_link ml ON h.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        h.level < 3  -- Limit the depth of recursion to 3 levels
),

-- Get actors for each movie
ActorMovies AS (
    SELECT 
        c.movie_id,
        a.name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),

-- Get movies with their actors and filter movies by a predicate
MoviesWithActors AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        a.name AS actor_name,
        a.actor_rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorMovies a ON mh.movie_id = a.movie_id
)

SELECT 
    mw.actor_name,
    mw.title,
    mw.production_year,
    COUNT(mw.actor_name) OVER (PARTITION BY mw.title) AS actor_count,
    MIN(mw.production_year) OVER (PARTITION BY mw.title) AS first_year
FROM 
    MoviesWithActors mw
WHERE 
    mw.actor_name IS NOT NULL  -- Filtering out rows with no actors
    AND mw.production_year IS NOT NULL
ORDER BY 
    mw.production_year DESC,
    actor_count DESC;

-- There could be NULL values in case some movies do not have actors,
-- so we perform filtering and ordering on non-null attributes.
This SQL query demonstrates the use of a recursive CTE to build a hierarchy of movies produced after 2000, along with their associated actors. The query leverages window functions for counting actors and getting the minimum production year per title while managing NULL values effectively. The final output is ordered by production year and actor count, providing insightful performance metrics across the movie database.
