
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN title t ON ml.linked_movie_id = t.id
),
cast_with_rank AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
),
movie_info_summary AS (
    SELECT
        mi.movie_id,
        STRING_AGG(CASE WHEN it.info = 'summary' THEN mi.info ELSE NULL END, ' ') AS summary,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    LEFT JOIN movie_keyword mk ON mi.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mi.movie_id
)
SELECT
    mh.title,
    mh.production_year,
    mcs.actor_name,
    mcs.actor_rank,
    mis.summary,
    COALESCE(mis.keywords, 'No keywords') AS keywords,
    (
        SELECT COUNT(*)
        FROM complete_cast cc
        WHERE cc.movie_id = mh.movie_id
    ) AS total_cast
FROM movie_hierarchy mh
LEFT JOIN cast_with_rank mcs ON mh.movie_id = mcs.movie_id
LEFT JOIN movie_info_summary mis ON mh.movie_id = mis.movie_id
WHERE mh.production_year >= 2000
  AND (mis.summary IS NOT NULL OR (
      SELECT COUNT(*)
      FROM complete_cast cc
      WHERE cc.movie_id = mh.movie_id
  ) > 0)
ORDER BY mh.production_year DESC, mh.title, mcs.actor_rank
LIMIT 50;
