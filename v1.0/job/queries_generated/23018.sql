WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        0 AS parent_id
    FROM title m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM title m
    JOIN movie_link ml ON ml.linked_movie_id = m.id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    mh.level,
    mh.title,
    mh.production_year,
    COALESCE(a.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    RANK() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank_within_level,
    CASE 
        WHEN COUNT(DISTINCT mc.company_id) = 0 THEN 'No Companies'
        ELSE 'Has Companies'
    END AS company_status,
    (SELECT COUNT(*)
     FROM aka_title at
     WHERE at.production_year = mh.production_year AND at.kind_id = 1) AS title_count_same_year
FROM movie_hierarchy mh
LEFT JOIN cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN aka_name a ON a.person_id = ci.person_id AND a.name IS NOT NULL
LEFT JOIN movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN keyword k ON k.id = mk.keyword_id
WHERE mh.production_year IS NOT NULL
GROUP BY mh.level, mh.movie_id, a.name
HAVING mh.production_year % 2 = 0 OR a.name IS NULL
ORDER BY mh.level, rank_within_level DESC;
