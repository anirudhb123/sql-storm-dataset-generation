WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
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
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    mh.depth,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_kinds,
    MAX(pi.info) FILTER (WHERE it.info = 'Biography') AS actor_biography,
    MIN(CASE WHEN cct.kind = 'Director' THEN mc.note END) AS director_note,
    AVG(COALESCE(NULLIF(c.norder, 0), 1)) AS avg_role_order -- Handle NULLs for nr_order
FROM
    aka_name ak
JOIN
    cast_info c ON ak.person_id = c.person_id
JOIN
    movie_hierarchy mh ON c.movie_id = mh.movie_id
JOIN
    aka_title at ON mh.movie_id = at.id
LEFT JOIN
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN
    company_type cct ON mc.company_type_id = cct.id
LEFT JOIN
    person_info pi ON ak.person_id = pi.person_id
LEFT JOIN
    info_type it ON pi.info_type_id = it.id
WHERE
    at.production_year BETWEEN 2000 AND 2023
    AND ak.name IS NOT NULL
GROUP BY
    ak.name, at.title, mh.production_year, mh.depth
HAVING
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY
    mh.depth DESC, ak.name;
