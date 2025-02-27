WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL

    UNION ALL

    SELECT
        m2.id AS movie_id,
        m2.title,
        m2.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title m2 ON ml.linked_movie_id = m2.id
    WHERE
        mh.level < 5  -- Limit the recursion depth
)

SELECT
    mt.title AS movie_title,
    COALESCE(c.name, 'Unknown') AS cast_member,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY COUNT(DISTINCT k.keyword) DESC) AS rank,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords_list
FROM
    MovieHierarchy mh
JOIN
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN
    aka_name c ON ci.person_id = c.person_id
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    aka_title mt ON mh.movie_id = mt.id
WHERE
    mt.production_year > 2000
    AND ci.note IS NULL -- Exclude casts with notes
GROUP BY
    mt.id, c.name
HAVING
    COUNT(DISTINCT k.keyword) > 0
ORDER BY
    mh.production_year DESC,
    rank
OPTION (MAXRECURSION 0);
