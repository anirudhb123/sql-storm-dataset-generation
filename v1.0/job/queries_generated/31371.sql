WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') AND
        mt.production_year >= 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        at.production_year >= 2000
)
SELECT
    mk.keyword,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    AVG(mh.level) AS avg_level
FROM
    MovieHierarchy mh
JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    info_type it ON mk.keyword_id = it.id
WHERE
    it.info IS NOT NULL
GROUP BY
    mk.keyword
HAVING
    COUNT(DISTINCT mh.movie_id) > 1
ORDER BY
    movie_count DESC
LIMIT 10;

-- Analysis of the overall performance
WITH MovieInfo AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mi.info, 'No Info') AS info
    FROM
        aka_title mt
    LEFT JOIN
        movie_info mi ON mt.id = mi.movie_id
),
PersonInfo AS (
    SELECT
        p.person_id,
        p.info,
        ROW_NUMBER() OVER (PARTITION BY p.person_id ORDER BY pi.note DESC) AS rn
    FROM
        person_info p
    JOIN
        info_type pi ON p.info_type_id = pi.id
    WHERE
        pi.info IS NOT NULL
)
SELECT
    mi.title,
    mi.production_year,
    pi.info AS person_info,
    COUNT(DISTINCT ci.person_id) AS cast_count
FROM
    MovieInfo mi
LEFT JOIN
    cast_info ci ON mi.movie_id = ci.movie_id
LEFT JOIN
    PersonInfo pi ON ci.person_id = pi.person_id AND pi.rn = 1
WHERE
    mi.production_year BETWEEN 2000 AND 2023
GROUP BY
    mi.title, mi.production_year, pi.info
HAVING
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY
    mi.production_year DESC, cast_count DESC
LIMIT 5;

-- Performance testing with NULL handling and multiple conditions
SELECT
    cn.name AS company_name,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    AVG(mi.info) FILTER (WHERE mi.info IS NOT NULL) AS avg_info_length
FROM
    company_name cn
LEFT JOIN
    movie_companies mc ON cn.id = mc.company_id
LEFT JOIN
    movie_info mi ON mc.movie_id = mi.movie_id
WHERE
    cn.country_code IS NOT NULL
GROUP BY
    cn.name
HAVING
    COUNT(DISTINCT mc.movie_id) > 3
ORDER BY
    avg_info_length DESC
LIMIT 10;
