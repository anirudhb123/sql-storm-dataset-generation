WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT
    a.name AS actor_name,
    th.title AS title,
    th.production_year,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
    COUNT(*) OVER (PARTITION BY a.name ORDER BY th.production_year) AS movie_count,
    AVG(mv.info_range) OVER (PARTITION BY a.name) AS avg_info_rating
FROM
    cast_info c
JOIN
    aka_name a ON c.person_id = a.person_id
JOIN
    MovieHierarchy th ON c.movie_id = th.movie_id
LEFT JOIN
    movie_keyword mk ON th.movie_id = mk.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN (
    SELECT
        mi.movie_id,
        AVG(CASE WHEN it.info = 'Rating' THEN CAST(mi.info AS FLOAT) END) AS info_range
    FROM
        movie_info mi
    JOIN
        info_type it ON mi.info_type_id = it.id
    WHERE
        it.info IN ('Rating', 'Box Office')
    GROUP BY
        mi.movie_id
) mv ON th.movie_id = mv.movie_id
WHERE
    a.name IS NOT NULL 
    AND th.production_year IS NOT NULL
    AND (kw.keyword IS NOT NULL OR a.name NOT LIKE '%Smith%')
    AND EXISTS (
        SELECT 1
        FROM complete_cast cc
        WHERE cc.movie_id = c.movie_id AND cc.status_id = 1
    )
GROUP BY
    a.name,
    th.title,
    th.production_year
ORDER BY
    th.production_year DESC, actor_name;
