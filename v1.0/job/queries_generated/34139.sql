WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM
        aka_title m
    WHERE
        m.production_year BETWEEN 2000 AND 2020

    UNION ALL

    SELECT
        mk.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM
        MovieHierarchy mh
    JOIN movie_link mk ON mh.movie_id = mk.movie_id
    JOIN aka_title mt ON mk.linked_movie_id = mt.id
    WHERE
        mh.depth < 5
), MovieCast AS (
    SELECT
        m.id AS movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY a.name) AS actor_order
    FROM
        aka_title m
    JOIN cast_info c ON m.id = c.movie_id
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    WHERE
        m.production_year > 2005
), KeywordCount AS (
    SELECT
        m.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN aka_title m ON mk.movie_id = m.id
    GROUP BY
        m.movie_id
), MovieInfo AS (
    SELECT
        m.id AS movie_id,
        mi.info AS movie_info,
        CASE WHEN mi.note IS NULL THEN 'No Additional Notes' ELSE mi.note END AS notes
    FROM
        aka_title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT c.actor_name) AS total_actors,
    COALESCE(kc.keyword_count, 0) AS total_keywords,
    STRING_AGG(DISTINCT i.movie_info, '; ') AS movie_info,
    SUM(CASE WHEN c.role_name = 'Director' THEN 1 ELSE 0 END) AS director_count
FROM
    MovieHierarchy mh
LEFT JOIN MovieCast c ON mh.movie_id = c.movie_id
LEFT JOIN KeywordCount kc ON mh.movie_id = kc.movie_id
LEFT JOIN MovieInfo i ON mh.movie_id = i.movie_id
GROUP BY
    mh.movie_id, mh.title, mh.production_year
HAVING
    COUNT(DISTINCT c.actor_name) > 5
ORDER BY
    total_keywords DESC,
    mh.production_year ASC;
