
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title, 
        mt.production_year,
        NULL::INTEGER AS parent_movie_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        a.title,
        a.production_year,
        mh.movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 4  
),

cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(role_type.role) AS notable_role
    FROM 
        cast_info ci
    JOIN 
        role_type ON ci.role_id = role_type.id
    GROUP BY 
        ci.movie_id
),

keyword_summary AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords_list
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
    COALESCE(cs.total_cast, 0) AS total_cast_count,
    COALESCE(ks.keywords_list, 'None') AS keyword_list,
    CASE 
        WHEN mh.level = 0 THEN 'Original Movie'
        WHEN mh.level BETWEEN 1 AND 2 THEN 'Direct Spin-off'
        ELSE 'Distant Reference'
    END AS movie_type,
    COALESCE(cs.notable_role, 'Unknown Role') AS notable_cast_role
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    keyword_summary ks ON mh.movie_id = ks.movie_id
ORDER BY 
    mh.production_year DESC,
    mh.level,
    mh.title
LIMIT 100;
