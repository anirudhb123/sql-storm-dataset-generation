WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, 
           mt.title, 
           mt.production_year, 
           0 AS level 
    FROM aka_title mt 
    WHERE mt.production_year IS NOT NULL 
      AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series')) 

    UNION ALL 

    SELECT mt.id AS movie_id, 
           mt.title, 
           mt.production_year, 
           mh.level + 1 
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id 
    JOIN aka_title mt ON ml.movie_id = mt.id 
    WHERE mt.production_year IS NOT NULL 
      AND mh.level < 5  
)
SELECT ak.name AS actor_name, 
       at.title AS movie_title, 
       at.production_year, 
       COUNT(DISTINCT mc.company_id) AS production_companies, 
       AVG(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) * 100 AS production_company_with_notes,
       (SELECT COUNT(DISTINCT kw.keyword) 
        FROM movie_keyword mk 
        JOIN keyword kw ON mk.keyword_id = kw.id 
        WHERE mk.movie_id = mh.movie_id) AS keyword_count,
       ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY at.production_year DESC) AS movie_rank
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN aka_title at ON mh.movie_id = at.id
LEFT JOIN movie_companies mc ON mc.movie_id = mh.movie_id 
GROUP BY ak.name, at.title, at.production_year
HAVING SUM(CASE WHEN mc.company_id IS NOT NULL THEN 1 ELSE 0 END) > 1
   AND COUNT(DISTINCT ci.movie_id) > 2
ORDER BY movie_rank ASC, production_year DESC
LIMIT 50;
