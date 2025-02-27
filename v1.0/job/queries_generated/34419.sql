WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS depth
    FROM
        title mt
    LEFT JOIN
        movie_link ml ON mt.id = ml.movie_id
    WHERE
        mt.production_year >= 2000

    UNION ALL

    SELECT
        mh.movie_id,
        t.title,
        t.production_year,
        ml.linked_movie_id,
        mh.depth + 1
    FROM
        MovieHierarchy mh
    INNER JOIN
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    INNER JOIN
        title t ON ml.linked_movie_id = t.id
)
SELECT
    t.id AS movie_id,
    t.title,
    t.production_year,
    COALESCE(NULLIF(CAST(SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 END) AS INTEGER), 0), 0) AS total_cast_size,
    STRING_AGG(DISTINCT ak.name, ', ') AS primary_names,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    MAX(CASE WHEN pi.info_type_id = 1 THEN pi.info END) AS premiere_info,
    COUNT(DISTINCT cct.kind) AS unique_company_types
FROM
    title t
LEFT JOIN
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN
    company_type cct ON mc.company_type_id = cct.id
LEFT JOIN
    cast_info ci ON t.id = ci.movie_id
LEFT JOIN
    aka_title ak ON t.id = ak.movie_id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN
    person_info pi ON mi.movie_id = t.id
WHERE
    t.production_year IS NOT NULL
    AND (cct.kind IS NOT NULL OR ci.person_id IS NOT NULL)
GROUP BY
    t.id, t.title, t.production_year
HAVING
    COUNT(DISTINCT ak.name) > 1
ORDER BY
    total_cast_size DESC, t.production_year ASC;
