WITH RECURSIVE MovieHierarchy AS (
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
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE
        mt.production_year >= 2000
)

SELECT
    p.name AS person_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(c.person_id) AS role_count,
    STRING_AGG(DISTINCT r.role, ', ') AS roles,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes,
    DENSE_RANK() OVER (PARTITION BY m.id ORDER BY COUNT(c.person_id) DESC) AS role_rank
FROM
    MovieHierarchy m
LEFT JOIN
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN
    aka_name p ON c.person_id = p.person_id
LEFT JOIN
    role_type r ON c.role_id = r.id
WHERE
    m.depth <= 3
    AND p.name IS NOT NULL
    AND m.production_year BETWEEN 2000 AND 2023
GROUP BY
    p.name, m.title, m.production_year
HAVING
    COUNT(c.person_id) > 1
ORDER BY
    m.production_year DESC, role_count DESC;
