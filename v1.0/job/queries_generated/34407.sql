WITH RECURSIVE movie_hierarchy AS (
    SELECT t.id AS movie_id, t.title, t.production_year, 
           COALESCE(ct.kind, 'Unknown') AS type_kind, 
           0 AS level
    FROM aka_title t
    LEFT JOIN kind_type ct ON t.kind_id = ct.id
    WHERE t.production_year >= 2000

    UNION ALL

    SELECT m.id AS movie_id, m.title, m.production_year, 
           COALESCE(ct.kind, 'Unknown') AS type_kind, 
           h.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy h ON ml.movie_id = h.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    LEFT JOIN kind_type ct ON m.kind_id = ct.id
)

, top_actors AS (
    SELECT a.id AS actor_id, ak.name AS actor_name, 
           COUNT(ci.movie_id) AS movie_count
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY a.id, ak.name
    ORDER BY movie_count DESC
    LIMIT 10
)

SELECT mh.movie_id, mh.title, mh.production_year, mh.type_kind, 
       ta.actor_name, ta.movie_count
FROM movie_hierarchy mh
INNER JOIN movie_companies mc ON mh.movie_id = mc.movie_id
INNER JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN top_actors ta ON ta.actor_id IN (
    SELECT ci.person_id 
    FROM cast_info ci
    WHERE ci.movie_id = mh.movie_id
)
WHERE (mh.production_year IS NOT NULL AND mh.production_year >= 2000)
  AND (cn.country_code IS NOT NULL AND cn.country_code != '')
  AND EXISTS (
      SELECT 1
      FROM movie_keyword mk
      WHERE mk.movie_id = mh.movie_id 
        AND mk.keyword_id IN (
            SELECT k.id 
            FROM keyword k 
            WHERE k.keyword ILIKE '%action%'
        )
  )
ORDER BY mh.production_year DESC, mh.title;
