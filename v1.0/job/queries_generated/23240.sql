WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year,
           NULL::integer AS parent_movie_id,
           1 AS level
    FROM aka_title m
    WHERE m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
          AND m.production_year IS NOT NULL

    UNION ALL

    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year,
           mh.movie_id AS parent_movie_id,
           mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN aka_title m ON ml.movie_id = m.id
)

SELECT DISTINCT 
       a.name AS actor_name,
       COUNT(CASE WHEN k.keyword IS NOT NULL THEN 1 END) AS keyword_count,
       AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE NULL END) AS avg_order,
       STRING_AGG(DISTINCT (mk.keyword || ' (' || mk.id || ')'), ', ') AS keywords_list,
       ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY m.production_year DESC) AS rank
FROM aka_name a
LEFT JOIN cast_info c ON a.person_id = c.person_id
LEFT JOIN aka_title m ON c.movie_id = m.id
LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN complete_cast cc ON m.id = cc.movie_id
LEFT JOIN movie_companies mc ON m.id = mc.movie_id
LEFT JOIN company_name cp ON mc.company_id = cp.id
JOIN movie_hierarchy mh ON mh.movie_id = m.id
WHERE a.name IS NOT NULL
AND (m.production_year > 2000 OR c.note IS NULL)
AND cp.country_code IS NOT NULL
GROUP BY a.name
HAVING COUNT(m.id) > 2
AND SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) > 1
ORDER BY rank DESC, keyword_count DESC;
