WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        1 AS level,
        ARRAY[m.id] AS path
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        mh.level + 1,
        path || m.id
    FROM
        aka_title m
    JOIN
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        m.production_year >= 2000
        AND NOT m.id = ANY(mh.path) 
)

SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    COUNT(ci.id) AS cast_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    FIRST_VALUE(t.production_year) OVER (PARTITION BY a.person_id ORDER BY t.production_year) AS first_production_year,
    SUM(CASE WHEN t.production_year > 2010 THEN 1 ELSE 0 END) AS modern_movies_count,
    COALESCE(MAX(m.info), 'No info available') AS movie_info
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    aka_title t ON ci.movie_id = t.id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_info m ON t.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot' LIMIT 1)
WHERE
    a.name IS NOT NULL
GROUP BY
    a.name, t.title
HAVING
    COUNT(DISTINCT ci.movie_id) >= 2
ORDER BY
    modern_movies_count DESC,
    a.name ASC;

WITH MovieAllData AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(SUM(CASE WHEN mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Distributor') THEN 1 ELSE 0 END), 0) AS distributor_count,
        ARRAY_AGG(DISTINCT c.name) AS companies
    FROM
        aka_title m
    LEFT JOIN
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN
        company_name c ON mc.company_id = c.id
    GROUP BY
        m.id, m.title
)

SELECT
    ma.movie_id,
    ma.title,
    ma.distributor_count,
    COALESCE(mo.movie_info, 'No additional info') AS additional_info,
    SUM(CASE WHEN mh.level IS NOT NULL THEN 1 ELSE 0 END) AS related_movies_count
FROM
    MovieAllData ma
LEFT JOIN
    movie_info mo ON ma.movie_id = mo.movie_id
LEFT JOIN
    MovieHierarchy mh ON ma.movie_id = mh.movie_id
GROUP BY
    ma.movie_id, ma.title, mo.movie_info
ORDER BY
    distributor_count DESC,
    additional_info ASC;
