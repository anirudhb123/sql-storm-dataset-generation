WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.movie_id,
        mt.title,
        mt.production_year,
        CAST(NULL AS INTEGER) AS parent_movie_id,
        0 AS depth
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    UNION ALL
    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.movie_id,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    at.title AS movie_title,
    ARRAY_AGG(DISTINCT ac.name) AS cast_names,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    AVG(mi.info_length) AS average_info_length,
    MAX(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE -1 END) AS max_order,
    COUNT(DISTINCT mc.company_id) AS production_company_count,
    COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS noted_roles_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM
    aka_title at
LEFT JOIN
    cast_info ci ON at.movie_id = ci.movie_id
LEFT JOIN
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN
    movie_keyword mk ON at.movie_id = mk.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN
    movie_companies mc ON at.movie_id = mc.movie_id
LEFT JOIN
    company_name cn ON mc.company_id = cn.id
LEFT JOIN (
    SELECT
        movie_id,
        LENGTH(info) AS info_length
    FROM
        movie_info
) mi ON mi.movie_id = at.movie_id
WHERE
    at.production_year IS NOT NULL
GROUP BY
    at.movie_id, at.title
HAVING
    COUNT(DISTINCT an.name) > 5 -- At least 6 distinct cast members
ORDER BY
    average_info_length DESC,
    movie_title
LIMIT 10;

