WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id, 
        tt.title AS movie_title, 
        tt.production_year, 
        CAST(NULL AS INTEGER) AS parent_id,
        0 AS level
    FROM 
        aka_title tt
    LEFT JOIN 
        movie_link ml ON tt.id = ml.movie_id
    WHERE 
        tt.production_year IS NOT NULL

    UNION ALL

    SELECT
        mt.id AS movie_id, 
        tt.title AS movie_title, 
        tt.production_year, 
        mh.movie_id AS parent_id,
        mh.level + 1 AS level
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.linked_movie_id
    JOIN 
        aka_title tt ON ml.movie_id = tt.id
),
ActorRoles AS (
    SELECT
        ka.person_id,
        ka.name,
        c.role_id,
        rt.role AS role_description,
        ka.imdb_index AS actor_imdb_index,
        COUNT(DISTINCT cc.movie_id) AS movie_count
    FROM 
        aka_name ka
    JOIN 
        cast_info c ON ka.person_id = c.person_id
    LEFT JOIN 
        role_type rt ON c.role_id = rt.id
    LEFT JOIN 
        complete_cast cc ON c.movie_id = cc.movie_id
    GROUP BY 
        ka.person_id, ka.name, c.role_id, rt.role
),
TopActors AS (
    SELECT
        actor_names.name,
        actor_names.actor_imdb_index,
        actor_roles.role_description,
        actor_roles.movie_count,
        RANK() OVER (PARTITION BY actor_roles.role_id ORDER BY actor_roles.movie_count DESC) AS rank_position
    FROM 
        ActorRoles actor_roles
    JOIN 
        aka_name actor_names ON actor_roles.person_id = actor_names.person_id
    WHERE 
        actor_roles.movie_count >= 10
)
SELECT 
    mh.movie_title,
    mh.production_year,
    COALESCE(ta.name, 'Unknown Actor') AS actor_name,
    COALESCE(ta.role_description, 'N/A') AS role_description,
    COALESCE(ta.movie_count, 0) AS movie_count,
    mh.level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    TopActors ta ON mh.movie_id = ta.movie_id
WHERE 
    mh.production_year BETWEEN 2000 AND 2020
ORDER BY 
    mh.production_year DESC, mh.movie_title, mh.level;

This query combines a recursive common table expression (CTE) to build a hierarchy of movies and their relationships through the `movie_link` table. It also calculates actor roles, counts their movie appearances, and ranks them, ultimately returning a dataset about movies between 2000 and 2020, along with the associated top actors, their roles, and some NULL logic for handling non-existent relationships. The usage of `COALESCE` manages NULL cases to provide more user-friendly output for potential missing data.
