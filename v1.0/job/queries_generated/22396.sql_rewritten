WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year = (SELECT MAX(production_year) FROM aka_title)

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1 AS level
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.movie_id
    JOIN movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
),

cast_role_counts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE 
            WHEN rt.role ILIKE '%lead%' THEN 1 
            ELSE 0 
        END) AS lead_roles
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id
),

top_keywords AS (
    SELECT 
        mk.movie_id, 
        k.keyword, 
        RANK() OVER (PARTITION BY mk.movie_id ORDER BY COUNT(mk.keyword_id) DESC) AS rank
    FROM movie_keyword mk 
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id, k.keyword
),

final_output AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        c.total_cast,
        c.lead_roles,
        k.keyword AS top_keyword
    FROM movie_hierarchy mh
    LEFT JOIN cast_role_counts c ON mh.movie_id = c.movie_id
    LEFT JOIN top_keywords k ON mh.movie_id = k.movie_id AND k.rank = 1
)

SELECT 
    fo.movie_id,
    fo.movie_title,
    fo.production_year,
    COALESCE(fo.total_cast, 0) AS total_cast,
    COALESCE(fo.lead_roles, 0) AS lead_roles,
    CASE 
        WHEN fo.top_keyword IS NOT NULL THEN fo.top_keyword 
        ELSE 'No keywords available' 
    END AS top_keyword
FROM final_output fo
ORDER BY fo.production_year DESC, fo.total_cast DESC
LIMIT 50;