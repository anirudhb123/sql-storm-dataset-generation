WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)

SELECT
    mh.title,
    mh.production_year,
    count(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
    COALESCE(avg(pi.salary), 0) AS average_salary,
    SUM(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Award') THEN 1 ELSE 0 END) AS awards_count,
    COALESCE(MAX(mk.keyword), 'No Keywords') AS primary_keyword -- interesting case for keywords
FROM
    MovieHierarchy mh
LEFT JOIN
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN
    person_info pi ON ci.person_id = pi.person_id
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
WHERE
    mh.production_year >= 1990
    AND mh.production_year <= 2023
GROUP BY
    mh.movie_id,
    mh.title,
    mh.production_year
ORDER BY
    total_cast DESC,
    mh.production_year DESC;

-- Standalone Subquery for benchmarking: 
SELECT
    title,
    production_year,
    (
        SELECT COUNT(DISTINCT ci.person_id)
        FROM cast_info ci
        WHERE ci.movie_id = a.id
    ) AS total_cast,
    (
        SELECT STRING_AGG(a2.name, ', ')
        FROM cast_info ci2
        JOIN aka_name a2 ON ci2.person_id = a2.person_id
        WHERE ci2.movie_id = a.id
    ) AS cast_names
FROM
    aka_title a
WHERE
    a.production_year BETWEEN 1950 AND 2023
    AND (a.title ILIKE '%love%' OR a.title ILIKE '%adventure%')
    AND (EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = a.id
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
        AND mi.info IS NOT NULL
    ))
ORDER BY
    a.production_year DESC
LIMIT 10;
