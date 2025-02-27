WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM 
        aka_title mt
    INNER JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        c.kind AS role_type,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
),
movies_aggregated AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(cd.actor_name) AS total_actors,
        STRING_AGG(cd.actor_name, ', ') AS actor_list
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_details cd ON mh.movie_id = cd.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    ma.movie_id,
    ma.title,
    ma.production_year,
    ma.total_actors,
    ma.actor_list,
    CASE 
        WHEN ma.total_actors = 0 THEN 'No Cast Available'
        WHEN ma.total_actors < 5 THEN 'Less than 5 actors'
        ELSE 'Full Cast'
    END AS cast_status
FROM 
    movies_aggregated ma
WHERE 
    ma.production_year BETWEEN 2000 AND 2020
ORDER BY 
    ma.total_actors DESC,
    ma.production_year ASC
LIMIT 100;

-- This query retrieves information about movies from 2000 to 2020,
-- including the number of actors and a list of their names, while also
-- providing a cast status based on the total number of actors.
