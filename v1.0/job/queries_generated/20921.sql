WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 1990

    UNION ALL 

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.level + 1
    FROM 
        movie_link ml 
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
),
actor_roles AS (
    SELECT 
        ci.person_id, 
        rk.role AS role_name, 
        COUNT(ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        role_type rk ON ci.role_id = rk.id
    GROUP BY 
        ci.person_id, rk.role
),
enriched_actors AS (
    SELECT 
        an.name AS actor_name,
        ar.role_name,
        ar.movie_count,
        ROW_NUMBER() OVER (PARTITION BY an.id ORDER BY ar.movie_count DESC) AS rn
    FROM 
        aka_name an
    JOIN 
        actor_roles ar ON an.person_id = ar.person_id
    WHERE 
        an.name IS NOT NULL
)
SELECT 
    mh.movie_title,
    e.actor_name,
    e.role_name,
    e.movie_count,
    CASE 
        WHEN e.movie_count = 0 THEN 'No Roles'
        WHEN e.movie_count BETWEEN 1 AND 5 THEN 'Minor Role'
        WHEN e.movie_count BETWEEN 6 AND 10 THEN 'Supporting Role'
        ELSE 'Lead Role'
    END AS role_category
FROM 
    movie_hierarchy mh
LEFT JOIN 
    enriched_actors e ON e.rn = 1 -- Get only the primary role per actor
WHERE 
    mh.level < 3 -- Restrict to a "flattened" view of related movies
ORDER BY 
    mh.movie_title, role_category DESC, e.movie_count DESC
LIMIT 1000;
