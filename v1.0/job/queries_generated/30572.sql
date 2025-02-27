WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        mt.production_year,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        ct.id AS movie_id,
        ct.title,
        mh.level + 1,
        ct.production_year,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title ct
    INNER JOIN 
        MovieHierarchy mh ON ct.episode_of_id = mh.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(ci.person_id) OVER (PARTITION BY ci.movie_id) AS actor_count
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name ak ON ak.person_id = ci.person_id
),
MovieStats AS (
    SELECT 
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS unique_actors,
        MAX(ci.actor_count) AS max_actors_per_movie,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors_list
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastDetails ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = mh.movie_id)
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    MS.title,
    MS.production_year,
    MS.unique_actors,
    MS.max_actors_per_movie,
    COALESCE(MS.actors_list, 'No actors') AS actor_names
FROM 
    MovieStats MS
WHERE 
    MS.production_year BETWEEN 1990 AND 2020
ORDER BY 
    MS.production_year DESC, 
    MS.unique_actors DESC
LIMIT 10;
