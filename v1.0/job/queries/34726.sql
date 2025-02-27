
WITH RECURSIVE Film_CTE AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM
        aka_title t
    WHERE
        t.production_year >= 2000

    UNION ALL

    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        fc.level + 1
    FROM
        movie_link ml
    JOIN Film_CTE fc ON ml.movie_id = fc.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
)

SELECT
    ak.person_id AS person_id,
    ak.name AS aka_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT c.note) AS num_roles,
    AVG(COALESCE(c.nr_order, 0)) AS avg_order,
    STRING_AGG(DISTINCT c.note, ', ') AS role_notes,
    SUM(COALESCE(mi.info_type_id, 0)) AS total_info_types
FROM
    aka_name ak
INNER JOIN
    cast_info c ON ak.person_id = c.person_id
INNER JOIN
    title t ON c.movie_id = t.id
LEFT JOIN
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN
    Film_CTE fc ON t.id = fc.movie_id
WHERE
    ak.name IS NOT NULL
    AND (c.nr_order IS NOT NULL OR c.note IS NULL)
    AND t.production_year > 2010
GROUP BY
    ak.person_id, ak.name, t.title, t.production_year
HAVING
    COUNT(DISTINCT c.note) > 2
ORDER BY
    t.production_year DESC, ak.person_id;
