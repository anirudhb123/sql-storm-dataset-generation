WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_with_role AS (
    SELECT 
        ai.person_id,
        ai.movie_id,
        ai.nr_order,
        ct.kind AS role_name
    FROM 
        cast_info ai
    JOIN 
        comp_cast_type ct ON ai.person_role_id = ct.id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
actors_ranked AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
),
movie_info_with_status AS (
    SELECT 
        mi.movie_id,
        mi.info,
        CASE 
            WHEN mi.info IS NULL THEN 'Not Available'
            ELSE mi.info
        END AS status_info
    FROM 
        movie_info mi
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    STRING_AGG(DISTINCT cr.role_name, ', ') AS cast_roles,
    MIN(ci.nr_order) AS first_actor_order,
    MAX(ci.nr_order) AS last_actor_order,
    ati.status_info
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    cast_with_role cr ON mh.movie_id = cr.movie_id
LEFT JOIN 
    actors_ranked ar ON mh.movie_id = ar.movie_id 
LEFT JOIN 
    movie_info_with_status ati ON mh.movie_id = ati.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, ati.status_info
HAVING 
    COUNT(DISTINCT ar.person_id) > 1  
ORDER BY 
    mh.production_year DESC, mh.title;
