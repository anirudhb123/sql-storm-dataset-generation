WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        level + 1
    FROM
        movie_link ml
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    a.name AS actor_name,
    mt.title AS movie_title,
    mh.level,
    COUNT(DISTINCT m.kw.keyword) AS keyword_count,
    AVG(COALESCE(mi.info::numeric, 0)) AS avg_rating,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types
FROM
    cast_info ci
INNER JOIN
    aka_name a ON ci.person_id = a.person_id
INNER JOIN
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN
    movie_keyword mkw ON mh.movie_id = mkw.movie_id
LEFT JOIN
    keyword m.kw ON mkw.keyword_id = m.kw.id
LEFT JOIN
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    company_type c ON mc.company_type_id = c.id
LEFT JOIN
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')
WHERE
    a.name IS NOT NULL
GROUP BY
    a.name, mt.title, mh.level
HAVING
    COUNT(DISTINCT m.kw.keyword) > 0
ORDER BY
    mh.level, avg_rating DESC;
