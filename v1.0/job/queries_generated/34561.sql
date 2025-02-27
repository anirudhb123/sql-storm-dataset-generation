WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM aka_title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.depth + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mt.production_year,
    c.role_id,
    COUNT(*) OVER (PARTITION BY ak.id ORDER BY mt.production_year DESC) AS movie_count,
    AVG(CASE WHEN mt.production_year IS NOT NULL THEN 1.0 ELSE NULL END) OVER (PARTITION BY ak.id) AS avg_production_year,
    RANK() OVER (PARTITION BY ak.id ORDER BY mt.production_year DESC) AS movie_rank,
    COALESCE(NULLIF(c.note, ''), 'No comment') AS comment,
    CASE 
        WHEN mt.kind_id = 1 THEN 'Movie'
        WHEN mt.kind_id = 2 THEN 'TV Show'
        ELSE 'Other'
    END AS kind_description
FROM cast_info c
JOIN aka_name ak ON c.person_id = ak.person_id
JOIN movie_hierarchy mh ON c.movie_id = mh.movie_id
JOIN aka_title at ON c.movie_id = at.id
JOIN title mt ON mh.movie_id = mt.id
LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
WHERE c.nr_order IS NOT NULL
AND ak.name IS NOT NULL
AND mt.production_year BETWEEN 2000 AND 2023
ORDER BY ak.name, movie_rank
LIMIT 50;
