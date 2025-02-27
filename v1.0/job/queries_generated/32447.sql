WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- root nodes

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id 
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    a.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_company_count,
    MAX(mh.level) AS max_link_depth
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    aka_title at ON ci.movie_id = at.id
LEFT JOIN
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN
    MovieHierarchy mh ON at.id = mh.movie_id
WHERE
    at.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY
    a.id, at.id, at.title, at.production_year
HAVING
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY
    max_link_depth DESC, movie_title ASC;
