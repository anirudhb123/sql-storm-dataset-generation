WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year, 'Unknown') AS production_year,
        NULL::text AS parent_movie
    FROM 
        aka_title AS m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        COALESCE(e.production_year, 'Unknown') AS production_year,
        m.title AS parent_movie
    FROM 
        aka_title AS e
    JOIN 
        movie_hierarchy AS m ON e.episode_of_id = m.movie_id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        ci.nr_order,
        r.role AS role
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    JOIN 
        role_type AS r ON ci.role_id = r.id
),
filtered_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cd.actor_name,
        cd.role,
        ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY cd.nr_order) AS actor_order
    FROM 
        movie_hierarchy AS mh
    LEFT JOIN 
        cast_details AS cd ON mh.movie_id = cd.movie_id
    WHERE 
        mh.production_year::text != 'Unknown'
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    STRING_AGG(cd.actor_name || ' (' || cd.role || ')', ', ') AS actor_list,
    COUNT(cd.actor_name) AS total_actors
FROM 
    filtered_movies AS fm
LEFT JOIN 
    cast_details AS cd ON fm.movie_id = cd.movie_id
GROUP BY 
    fm.movie_id, fm.title, fm.production_year
HAVING 
    COUNT(cd.actor_name) > 0
ORDER BY 
    fm.production_year DESC,
    total_actors DESC;
