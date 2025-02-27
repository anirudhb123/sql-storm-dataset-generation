
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COALESCE(ml.linked_movie_id, 0) AS linked_movie_id,
        0 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COALESCE(ml.linked_movie_id, 0),
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON mt.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.linked_movie_id = mt.id
    WHERE 
        mh.level < 3
),
cast_with_roles AS (
    SELECT 
        c.movie_id,
        p.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
info_summary AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        COUNT(DISTINCT km.keyword) AS associated_keywords,
        STRING_AGG(DISTINCT p.info, ', ') AS person_info
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword km ON mk.keyword_id = km.id
    LEFT JOIN 
        person_info p ON m.id = p.person_id
    GROUP BY 
        m.id, m.title
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    cw.actor_name,
    cw.role_name,
    isum.production_companies,
    isum.associated_keywords,
    isum.person_info,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY cw.actor_rank) AS actor_position
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_with_roles cw ON mh.movie_id = cw.movie_id
LEFT JOIN 
    info_summary isum ON mh.movie_id = isum.movie_id
WHERE 
    mh.level = 0
ORDER BY 
    mh.production_year DESC,
    mh.movie_id,
    actor_position
LIMIT 100;
