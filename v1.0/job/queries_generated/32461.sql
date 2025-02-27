WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS depth
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        CONCAT(m.title, ' (Linked to: ', mh.movie_title, ')') AS movie_title,
        mh.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN aka_title m ON ml.movie_id = m.id
)
SELECT
    ak.name AS actor_name,
    mt.movie_title,
    mt.production_year,
    COUNT(DISTINCT mc.company_id) AS production_company_count,
    AVG(mi.info_length) AS avg_info_length,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY mt.production_year DESC) AS movie_rank
FROM
    aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN movie_companies mc ON ci.movie_id = mc.movie_id
JOIN movie_info mi ON ci.movie_id = mi.movie_id
JOIN movie_hierarchy mt ON ci.movie_id = mt.movie_id
LEFT JOIN (
    SELECT
        movie_id,
        LENGTH(info) AS info_length
    FROM
        movie_info
    WHERE
        info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'Length%')
) AS mi ON mi.movie_id = ci.movie_id
WHERE
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND mt.depth <= 2
GROUP BY
    ak.id, mt.movie_id
HAVING
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY
    movie_rank, ak.actor_name;
