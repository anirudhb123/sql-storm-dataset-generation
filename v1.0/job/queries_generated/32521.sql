WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_id,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT
        mm.id AS movie_id,
        mm.title,
        mm.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM
        aka_title mm
    JOIN movie_link ml ON ml.movie_id = mh.movie_id
    JOIN MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
)
SELECT
    h.title AS movie_title,
    h.production_year,
    CAST(COALESCE(c.nm_count, 0) AS integer) AS named_count,
    h.level,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS directors_count
FROM
    MovieHierarchy h
LEFT JOIN
    complete_cast cc ON h.movie_id = cc.movie_id
LEFT JOIN
    cast_info c ON cc.subject_id = c.person_id AND c.nr_order IS NOT NULL
LEFT JOIN
    aka_name a ON c.person_id = a.person_id
LEFT JOIN
    movie_keyword mk ON h.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_info mi ON h.movie_id = mi.movie_id
WHERE
    h.production_year IS NOT NULL
GROUP BY
    h.title, h.production_year, h.level
HAVING
    COUNT(DISTINCT c.person_id) > 1
ORDER BY
    h.production_year DESC, h.title;
