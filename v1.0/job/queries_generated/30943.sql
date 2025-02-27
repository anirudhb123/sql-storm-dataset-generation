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
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    p.name AS actor_name,
    COUNT(DISTINCT ch.movie_id) AS movie_count,
    AVG(mh.depth) AS avg_depth,
    STRING_AGG(DISTINCT at.title, ', ') AS titles
FROM
    aka_name p
JOIN cast_info ci ON p.person_id = ci.person_id
JOIN movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN aka_title at ON at.id = ci.movie_id
LEFT JOIN complete_cast cc ON cc.movie_id = at.id
LEFT JOIN movie_companies mc ON mc.movie_id = at.id
LEFT JOIN company_name cn ON mc.company_id = cn.id AND cn.country_code IS NOT NULL
WHERE
    at.production_year IS NOT NULL
    AND p.name IS NOT NULL
GROUP BY
    p.name
HAVING
    COUNT(DISTINCT ch.movie_id) > 5
ORDER BY
    movie_count DESC
LIMIT 10;
