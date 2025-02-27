WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM
        aka_title t
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    WHERE
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Distributor')

    UNION ALL

    SELECT
        mh.movie_id,
        t.title,
        mh.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title t ON ml.linked_movie_id = t.id
)
SELECT
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(CONCAT(a.name, ' (', a.person_id, ')'), 'Unknown') AS actor_name,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.id) OVER (PARTITION BY m.movie_id) AS total_cast,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS year_rank
FROM
    MovieHierarchy m
LEFT JOIN
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN
    aka_name a ON c.person_id = a.person_id
LEFT JOIN
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
WHERE
    (m.production_year IS NOT NULL AND m.production_year >= 2000)
    OR (m.level = 1 AND m.production_year IS NULL)
GROUP BY
    m.movie_id, m.title, m.production_year, a.name, a.person_id
ORDER BY
    m.production_year DESC, m.title;
