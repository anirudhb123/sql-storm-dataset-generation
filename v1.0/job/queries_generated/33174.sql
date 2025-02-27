WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT mt.id, mt.title, mt.production_year, mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
)
, actor_details AS (
    SELECT 
        ak.name AS actor_name,
        ct.kind AS role,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        SUM(CASE WHEN mt.production_year >= 2020 THEN 1 ELSE 0 END) AS recent_movies_count
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rt ON ci.role_id = rt.id
    JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    LEFT JOIN aka_title mt ON ci.movie_id = mt.id
    GROUP BY ak.name, ct.kind
)
, movie_info_summary AS (
    SELECT 
        mt.id,
        mt.title,
        COUNT(mk.keyword_id) AS keyword_count,
        COALESCE(SUM(mi.info_type_id), 0) AS info_types_count
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN movie_info mi ON mt.id = mi.movie_id
    GROUP BY mt.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ad.actor_name,
    ad.role,
    ad.movie_count,
    ad.recent_movies_count,
    mis.keyword_count,
    mis.info_types_count
FROM movie_hierarchy mh
JOIN actor_details ad ON ad.movie_count > 0
LEFT JOIN movie_info_summary mis ON mh.movie_id = mis.id
WHERE ad.recent_movies_count > 0
ORDER BY mh.production_year DESC, ad.movie_count DESC
LIMIT 100;

