WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(NULLIF(mk.keyword, ''), 'Unknown') AS keyword,
        1 AS level
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    WHERE
        m.production_year IS NOT NULL

    UNION ALL

    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        COALESCE(NULLIF(mk.keyword, ''), 'Unknown') AS keyword,
        mh.level + 1
    FROM
        movie_hierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
    LEFT JOIN
        movie_keyword mk ON mt.id = mk.movie_id
)

SELECT
    m.id AS movie_id,
    m.title,
    m.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast,
    STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
    ARRAY_AGG(DISTINCT mk.keyword) AS associated_keywords,
    MAX(COALESCE(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') THEN pi.info END, 'N/A')) AS movie_rating,
    SUM(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'BoxOffice') THEN CAST(pi.info AS DECIMAL) ELSE 0 END) AS total_box_office
FROM
    movie_hierarchy m
LEFT JOIN
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN
    aka_name a ON c.person_id = a.person_id
LEFT JOIN
    movie_info pi ON m.movie_id = pi.movie_id
LEFT JOIN
    movie_keyword mk ON m.movie_id = mk.movie_id
GROUP BY
    m.id, m.title, m.production_year
HAVING
    COUNT(DISTINCT c.person_id) > 0 AND movie_rating IS NOT NULL
ORDER BY
    total_cast DESC, production_year DESC;
