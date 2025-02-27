WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::integer AS parent_movie_id,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        mk.linked_movie_id AS movie_id,
        mk.linked_movie_title AS title,
        mk.linked_movie_year AS production_year,
        m.id AS parent_movie_id,
        h.level + 1 AS level
    FROM
        movie_link mk
    JOIN
        movie_hierarchy h ON mk.movie_id = h.movie_id
    JOIN
        aka_title m ON mk.linked_movie_id = m.id
)

SELECT
    a.name AS actor_name,
    mt.title AS movie_title,
    mh.level,
    COUNT(DISTINCT mc.company_id) AS production_company_count,
    STRING_AGG(DISTINCT comp.name, ', ') AS companies,
    AVG(mi.rating) AS average_rating,
    COUNT(DISTINCT kw.keyword) AS keyword_count
FROM
    cast_info ci
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN
    company_name comp ON mc.company_id = comp.id
LEFT JOIN
    movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
JOIN
    movie_hierarchy mh ON mt.id = mh.movie_id
WHERE
    a.name IS NOT NULL
    AND mt.production_year BETWEEN 2000 AND 2023
    AND (ci.note IS NULL OR ci.note != '')
GROUP BY
    a.name, mt.title, mh.level
ORDER BY
    mh.level DESC,
    average_rating DESC
LIMIT 100;
