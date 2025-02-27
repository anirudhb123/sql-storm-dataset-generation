-- Performance benchmarking query involving various complex SQL features
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS depth
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL AND m.production_year >= 2000
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        CONCAT(mh.movie_title, ' -> ', mt.title),
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT
    ak.name AS actor_name,
    mt.movie_title,
    COUNT(DISTINCT ak.id) AS actor_count,
    MAX(comp.kind) AS primary_company,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY mt.production_year DESC) AS actor_movie_rank
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN
    company_type comp ON mc.company_type_id = comp.id
JOIN
    movie_info mi ON ci.movie_id = mi.movie_id
JOIN
    movie_keyword mk ON ci.movie_id = mk.movie_id
JOIN
    keyword kw ON mk.keyword_id = kw.id
JOIN
    movie_hierarchy mt ON ci.movie_id = mt.movie_id
WHERE
    ak.name IS NOT NULL
    AND ak.md5sum IS NOT NULL
    AND (ci.note IS NULL OR ci.note != 'Cameo')
    AND (comp.kind LIKE '%Production%' OR comp.kind IS NULL)
    AND mt.depth <= 3
GROUP BY
    ak.name, mt.movie_title
HAVING
    COUNT(DISTINCT ak.id) > 1
ORDER BY
    actor_movie_rank,
    actor_name;

