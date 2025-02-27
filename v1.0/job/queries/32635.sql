
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL AS parent_movie_id,
        1 AS level
    FROM 
        title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    
    UNION ALL 
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM 
        title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.level < 5 
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rn
    FROM 
        movie_hierarchy mh
),
actor_roles AS (
    SELECT 
        ca.movie_id,
        a.name AS actor_name,
        rt.role AS role_description,
        COUNT(*) AS role_count
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON a.person_id = ca.person_id
    JOIN 
        role_type rt ON rt.id = ca.role_id
    GROUP BY 
        ca.movie_id, a.name, rt.role
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.level,
    a.actor_name,
    a.role_description,
    COALESCE(mk.keywords_list, 'No Keywords') AS keywords,
    COALESCE(a.role_count, 0) AS total_roles
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_roles a ON a.movie_id = rm.movie_id
LEFT JOIN 
    movie_keywords mk ON mk.movie_id = rm.movie_id
WHERE 
    rm.rn <= 5 
ORDER BY 
    rm.production_year DESC, rm.level ASC;
