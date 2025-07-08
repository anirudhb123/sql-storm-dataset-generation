
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level
    FROM
        aka_title t
    WHERE
        t.production_year >= 2000

    UNION ALL

    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        aka_title t ON t.episode_of_id = mh.movie_id
)

SELECT
    m.title AS movie_title,
    m.production_year AS year,
    COALESCE(cn.name, 'Unknown') AS company_name,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes,
    LISTAGG(DISTINCT ak.name, ', ') AS aka_names,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS ranking
FROM
    MovieHierarchy m
LEFT JOIN
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN
    company_name cn ON mc.company_id = cn.id
LEFT JOIN
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN
    aka_name ak ON ci.person_id = ak.person_id
WHERE
    m.production_year IS NOT NULL
    AND m.production_year BETWEEN 2000 AND 2023
GROUP BY
    m.movie_id, m.title, m.production_year, cn.name
HAVING
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY
    year DESC,
    ranking ASC;
