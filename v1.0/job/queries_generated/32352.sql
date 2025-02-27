WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id 
    WHERE 
        mh.level < 5
),
cast_info_with_role AS (
    SELECT 
        ci.id AS cast_id,
        ci.movie_id,
        ci.person_id,
        rt.role,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
person_details AS (
    SELECT 
        an.name AS actor_name,
        pi.info AS actor_info
    FROM 
        aka_name an
    JOIN 
        person_info pi ON an.person_id = pi.person_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.title AS movie_title,
    mh.level AS link_level,
    cwr.actor_name,
    cwr.role,
    cwr.role_order,
    ci.company_name,
    ci.company_type,
    ks.keywords,
    CASE 
        WHEN cwr.role IS NULL THEN 'No Role Assigned'
        ELSE cwr.role
    END AS role_description
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info_with_role cwr ON mh.movie_id = cwr.movie_id
LEFT JOIN 
    company_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    keyword_summary ks ON mh.movie_id = ks.movie_id
WHERE 
    mh.level = 1
ORDER BY 
    mh.title,
    cwr.role_order
LIMIT 100;
