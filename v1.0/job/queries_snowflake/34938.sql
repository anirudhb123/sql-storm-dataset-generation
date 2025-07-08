
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        submovie.id AS movie_id,
        submovie.title,
        submovie.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM 
        aka_title submovie
    JOIN 
        movie_hierarchy mh ON submovie.episode_of_id = mh.movie_id
),
cast_info_with_roles AS (
    SELECT 
        ai.name AS actor_name,
        at.title AS movie_title,
        COALESCE(rt.role, 'Unknown Role') AS role,
        ci.movie_id
    FROM 
        cast_info ci
    JOIN 
        aka_name ai ON ci.person_id = ai.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level) AS rank
    FROM 
        movie_hierarchy mh
)

SELECT 
    r.rank,
    r.title AS movie_title,
    r.production_year,
    LISTAGG(c.actor_name || ' (' || c.role || ')', ', ') WITHIN GROUP (ORDER BY c.actor_name) AS cast_details,
    COUNT(DISTINCT c.actor_name) AS total_cast
FROM 
    ranked_movies r
LEFT JOIN 
    cast_info_with_roles c ON r.movie_id = c.movie_id
GROUP BY 
    r.rank, r.movie_id, r.title, r.production_year
HAVING 
    COUNT(DISTINCT c.actor_name) > 3
ORDER BY 
    r.production_year DESC, r.rank ASC;
