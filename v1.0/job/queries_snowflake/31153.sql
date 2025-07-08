
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title AS m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link AS ml
    JOIN
        aka_title AS m ON ml.linked_movie_id = m.id
    JOIN
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3
),

cast_details AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    JOIN 
        role_type AS r ON ci.role_id = r.id
),

movies_with_cast AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cd.actor_name,
        cd.role,
        cd.actor_order
    FROM 
        movie_hierarchy AS mh
    LEFT JOIN 
        cast_details AS cd ON mh.movie_id = cd.movie_id
)

SELECT 
    mwc.movie_id,
    mwc.title,
    mwc.production_year,
    LISTAGG(mwc.actor_name || ' (' || mwc.role || ')', ', ') WITHIN GROUP (ORDER BY mwc.actor_order) AS cast,
    COUNT(DISTINCT mwc.actor_name) AS total_actors
FROM 
    movies_with_cast AS mwc
GROUP BY 
    mwc.movie_id, mwc.title, mwc.production_year
HAVING 
    COUNT(DISTINCT mwc.actor_name) > 5
ORDER BY 
    mwc.production_year DESC, total_actors DESC;
