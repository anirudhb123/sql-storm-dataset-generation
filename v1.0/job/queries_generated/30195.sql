WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000  -- Filter for movies from year 2000 onward

    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(ci.id) AS cast_count,
    STRING_AGG(DISTINCT ct.kind, ', ') AS company_types,
    AVG(mii.info_text_length) AS average_info_length,
    MAX(mh.level) AS max_hierarchy_level
FROM
    aka_name ak 
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN (
    SELECT
        movie_id,
        LENGTH(info) AS info_text_length
    FROM
        movie_info
    WHERE
        info_type_id IN (SELECT id FROM info_type WHERE info = 'Plot')
) mii ON mt.id = mii.movie_id
LEFT JOIN
    movie_hierarchy mh ON mt.id = mh.movie_id
WHERE
    ak.name IS NOT NULL  -- Exclude actors without names
GROUP BY
    ak.name, mt.title, mt.production_year
HAVING
    COUNT(ci.id) > 2  -- Only include movies with more than 2 cast members
ORDER BY
    average_info_length DESC, 
    production_year ASC;
