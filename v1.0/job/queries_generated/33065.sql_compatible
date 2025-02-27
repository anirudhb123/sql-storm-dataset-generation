
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    SUM(CASE WHEN pi.info IS NOT NULL THEN 1 ELSE 0 END) AS info_count,
    AVG(ci.nr_order) AS avg_order,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY a.name) AS actor_rank
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    aka_title m ON ci.movie_id = m.id
LEFT JOIN
    movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN
    movie_info mi ON mi.movie_id = m.id
LEFT JOIN
    movie_info_idx pi ON pi.movie_id = m.id
WHERE
    m.production_year BETWEEN 2000 AND 2023
    AND (a.name ILIKE '%Smith%' OR a.name ILIKE '%Johnson%')
GROUP BY
    a.name, m.id, m.title, m.production_year
HAVING
    COUNT(DISTINCT kc.keyword) > 0 AND
    AVG(ci.nr_order) > 2
ORDER BY
    m.production_year DESC, actor_rank;
