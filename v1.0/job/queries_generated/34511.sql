WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        NULL AS parent_movie_id, 
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mh.movie_id AS parent_movie_id, 
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),

CastWithRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),

MoviesWithInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year, 0) AS production_year,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        MIN(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') THEN mi.info END) AS budget,
        MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre') THEN mi.info END) AS genre
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.parent_movie_id,
    cwr.actor_name,
    cwr.role_name,
    mw.production_year,
    mw.keywords,
    mw.budget,
    mw.genre,
    COUNT(DISTINCT cwr.actor_name) OVER (PARTITION BY mh.movie_id) AS total_cast
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastWithRoles cwr ON mh.movie_id = cwr.movie_id
JOIN 
    MoviesWithInfo mw ON mh.movie_id = mw.movie_id
WHERE 
    mw.budget IS NOT NULL
ORDER BY 
    mh.level DESC, 
    mw.production_year ASC, 
    total_cast DESC;

This query utilizes several SQL features:
- A recursive CTE (`MovieHierarchy`) to create a hierarchy of movies and their episodes.
- A CTE (`CastWithRoles`) to gather cast information, including the actor's name and their role, and assigns a rank to each actor in a movie.
- Another CTE (`MoviesWithInfo`) aggregates movie information including keywords and information types such as budget and genre.
- The main SELECT combines these CTEs to provide a comprehensive output of movies, cast members, and their details.
- The use of `COALESCE` to handle NULL values and `STRING_AGG` for creating a comma-separated list of keywords.
- Window functions to calculate total cast count for each movie.

This structure allows for performance benchmarking over complex SQL queries, providing insights into data retrieval times and efficiency across various join operations and aggregations.
