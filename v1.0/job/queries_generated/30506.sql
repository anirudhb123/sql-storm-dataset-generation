WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 0 AS level
    FROM aka_title m
    WHERE m.production_year >= 2000
    UNION ALL
    SELECT m.id, m.title, m.production_year, mh.level + 1
    FROM movie_link ml
    INNER JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    INNER JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE mh.level < 2  -- Limit the hierarchy depth
),
cast_with_roles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM cast_info ci
    INNER JOIN aka_name ak ON ci.person_id = ak.person_id
    INNER JOIN role_type rt ON ci.role_id = rt.id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    INNER JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_summary AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(k.keywords, 'No keywords') AS keywords,
        COUNT(DISTINCT c.actor_name) AS actor_count,
        AVG(CASE WHEN c.role_rank = 1 THEN 1 ELSE 0 END) AS lead_actor_percentage
    FROM movie_hierarchy mh
    LEFT JOIN cast_with_roles c ON mh.movie_id = c.movie_id
    LEFT JOIN movie_keywords k ON mh.movie_id = k.movie_id
    GROUP BY mh.movie_id, mh.title, mh.production_year, k.keywords
)
SELECT 
    ms.title,
    ms.production_year,
    ms.keywords,
    ms.actor_count,
    CASE 
        WHEN ms.actor_count > 0 THEN ROUND(ms.lead_actor_percentage * 100, 2)
        ELSE 0
    END AS lead_actor_percentage
FROM movie_summary ms
ORDER BY ms.production_year DESC, ms.actor_count DESC;
