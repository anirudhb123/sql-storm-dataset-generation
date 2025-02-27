WITH RECURSIVE actor_hierarchy AS (
    SELECT ci.person_id, 
           ak.name AS actor_name,
           1 AS level
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE ci.movie_id IN (SELECT id FROM aka_title WHERE kind_id = 1) 
    
    UNION ALL

    SELECT ci.person_id, 
           ak.name AS actor_name,
           ah.level + 1
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN actor_hierarchy ah ON ci.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id)
)

SELECT at.title AS movie_title,
       COUNT(DISTINCT ci.person_id) AS total_actors,
       STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
       SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count,
       MAX(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS highest_order,
       STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
       ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_actor_count
FROM aka_title at
LEFT JOIN cast_info ci ON at.id = ci.movie_id
LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
WHERE at.production_year BETWEEN 2000 AND 2020
  AND ak.name IS NOT NULL
GROUP BY at.title, at.production_year
HAVING COUNT(DISTINCT ci.person_id) > 10
ORDER BY total_actors DESC, at.production_year ASC;