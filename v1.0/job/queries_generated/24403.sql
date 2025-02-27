WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id,
           mt.title,
           mt.production_year,
           0 AS hierarchy_level
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
      AND mt.production_year IS NOT NULL

    UNION ALL

    SELECT mt.id,
           mt.title,
           mt.production_year,
           mh.hierarchy_level + 1
    FROM movie_link ml
    INNER JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    INNER JOIN aka_title mt ON ml.linked_movie_id = mt.id
    WHERE ml.link_type_id IN (SELECT id FROM link_type WHERE link = 'sequel')
)
, cast_roles AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS distinct_actors,
           SUM(CASE WHEN ci.nr_order IS NULL OR ci.nr_order < 1 THEN 1 ELSE 0 END) AS unranked_roles
    FROM cast_info ci
    GROUP BY ci.movie_id
)
, keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT mh.movie_id,
       mh.title,
       mh.production_year,
       COALESCE(cr.distinct_actors, 0) AS actors_count,
       COALESCE(cr.unranked_roles, 0) AS unranked_roles_count,
       COALESCE(kc.keyword_count, 0) AS keywords_assigned,
       CASE 
           WHEN mh.production_year < 2000 THEN 'Classic'
           WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
           ELSE 'Recent'
       END AS era,
       RANK() OVER (PARTITION BY mh.hierarchy_level ORDER BY mh.production_year DESC) AS rank_in_hierarchy
FROM movie_hierarchy mh
LEFT JOIN cast_roles cr ON mh.movie_id = cr.movie_id
LEFT JOIN keyword_counts kc ON mh.movie_id = kc.movie_id
WHERE mh.title IS NOT NULL
  AND (mh.production_year IS NOT NULL OR mh.title LIKE '%%')
ORDER BY mh.production_year DESC NULLS LAST
OPTION (FORCE ORDER);
