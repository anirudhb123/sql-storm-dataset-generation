WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.id
    WHERE 
        m.production_year IS NOT NULL
)
,
cast_with_roles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
)
,
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cwr.actor_name, 'No Cast') AS leading_actor,
    COALESCE(cwr.role, 'Undefined Role') AS actor_role,
    COALESCE(mk.keywords_list, '(No Keywords)') AS keywords,
    mh.level AS hierarchical_level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_with_roles cwr ON mh.movie_id = cwr.movie_id AND cwr.role_order = 1
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.level <= 3
ORDER BY 
    mh.production_year DESC, mh.title ASC
LIMIT 50;
