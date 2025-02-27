WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
average_role_assignments AS (
    SELECT 
        ci.movie_id,
        AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
cast_with_null AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        COALESCE(a.name, 'Unknown Actor') AS actor_name,
        COALESCE(rt.role, 'Unspecified Role') AS role
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        role_type rt ON c.role_id = rt.id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(mk.keyword_id::text, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    COALESCE(cw.actor_name, 'No Cast Found') AS lead_actor,
    COALESCE(AVG(ar.avg_roles), 0) AS avg_roles_per_movie,
    COALESCE(mk.keyword_list, 'No Keywords') AS keywords,
    mh.level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_with_null cw ON mh.movie_id = cw.movie_id
LEFT JOIN 
    average_role_assignments ar ON mh.movie_id = ar.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
GROUP BY 
    mh.movie_id, mh.title, cw.actor_name, ar.avg_roles, mk.keyword_list, mh.level
HAVING 
    mh.level <= 2
ORDER BY 
    mh.level, mh.title;
