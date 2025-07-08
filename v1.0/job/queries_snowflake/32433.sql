
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        NULL AS parent_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL  

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title AS movie_title,
        e.production_year,
        h.movie_id AS parent_id,
        h.level + 1
    FROM 
        aka_title e
    INNER JOIN 
        movie_hierarchy h ON e.episode_of_id = h.movie_id  
),
actor_roles AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        r.role AS role_name,
        ROW_NUMBER() OVER(PARTITION BY ca.person_id ORDER BY ca.nr_order) AS role_order
    FROM 
        cast_info ca
    JOIN 
        role_type r ON ca.role_id = r.id
),
movie_info_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.id, m.title, m.production_year
),
company_movie_info AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
complete_movie_data AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COALESCE(k.keywords, ARRAY_CONSTRUCT()) AS keywords,
        COALESCE(cr.count, 0) AS role_count,
        COALESCE(cc.company_count, 0) AS company_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_info_with_keywords k ON mh.movie_id = k.movie_id
    LEFT JOIN 
        (SELECT movie_id, COUNT(DISTINCT person_id) AS count
         FROM actor_roles 
         GROUP BY movie_id) cr ON mh.movie_id = cr.movie_id
    LEFT JOIN 
        company_movie_info cc ON mh.movie_id = cc.movie_id
)
SELECT 
    movie_title, 
    production_year, 
    keywords, 
    role_count, 
    company_count
FROM 
    complete_movie_data
WHERE 
    production_year > 2000
ORDER BY 
    production_year DESC, 
    role_count DESC;
