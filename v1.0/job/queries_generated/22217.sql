WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        mt.id::text AS path
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        mh.path || '->' || ml.linked_movie_id::text
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mh.production_year AS year,
    COUNT(dc.person_id) AS co_actors,
    STRING_AGG(DISTINCT CASE 
        WHEN ci.note IS NOT NULL THEN ci.note 
        ELSE 'No note' END, ', ' ORDER BY ci.note) AS notes,
    SUM(CASE 
        WHEN ci.nr_order IS NULL THEN 0 
        ELSE ci.nr_order END) AS total_order,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY COUNT(dc.person_id) DESC) AS actor_rank
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN movie_companies mc ON ci.movie_id = mc.movie_id
JOIN aka_title mt ON ci.movie_id = mt.id
LEFT JOIN movie_keyword mk ON mk.movie_id = mt.id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN complete_cast cc ON cc.movie_id = mt.id
LEFT JOIN (SELECT person_id, movie_id FROM cast_info GROUP BY person_id, movie_id) dc ON ci.movie_id = dc.movie_id AND ci.person_id <> dc.person_id
LEFT JOIN movie_hierarchy mh ON mh.movie_id = mt.id
WHERE ak.name IS NOT NULL
AND mt.production_year >= 2000
AND (ci.note LIKE '%lead%' OR ci.note IS NULL)
GROUP BY ak.name, mt.title, mh.production_year
HAVING COUNT(DISTINCT ci.person_id) > 5
ORDER BY actor_rank;
