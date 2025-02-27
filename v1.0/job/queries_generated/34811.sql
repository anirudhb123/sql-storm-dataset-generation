WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        COALESCE(wa.released_year, mt.production_year) AS released_year,
        1 AS level
    FROM aka_title mt
    LEFT JOIN (
        SELECT 
            ml.linked_movie_id,
            mt.production_year AS released_year
        FROM movie_link ml
        JOIN aka_title mt ON ml.linked_movie_id = mt.id
    ) wa ON mt.id = wa.linked_movie_id

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title AS movie_title,
        COALESCE(wa.released_year, mt.production_year) AS released_year,
        mh.level + 1
    FROM movie_hierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    ak.name AS actor_name,
    ak.id AS actor_id,
    mh.movie_title,
    mh.released_year,
    COUNT(DISTINCT cc.id) AS character_count,
    MAX(CASE WHEN cc.nr_order IS NOT NULL THEN cc.nr_order ELSE 0 END) AS max_order,
    STRING_AGG(DISTINCT CONCAT(kt.keyword, ' (' ,ktr.kind, ')'), ', ') AS movie_keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY mh.released_year DESC) AS ranking
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN keyword kt ON mk.keyword_id = kt.id
LEFT JOIN kind_type ktr ON kt.phonetic_code = ktr.id
LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
WHERE ak.name IS NOT NULL
GROUP BY ak.id, ak.name, mh.movie_title, mh.released_year
HAVING COUNT(DISTINCT cc.id) > 0 AND 
       SUM(COALESCE(cc.status_id, 0)) > 1
ORDER BY ranking;
