WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        NULL AS parent_movie_id
    FROM
        aka_title mt
    WHERE
        mt.id IS NOT NULL

    UNION ALL

    SELECT
        ml.linked_movie_id,
        lt.title,
        lt.production_year,
        mh.level + 1,
        mh.movie_id AS parent_movie_id
    FROM
        movie_link ml
    JOIN
        title lt ON ml.linked_movie_id = lt.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    ak.name AS actor_name,
    mv.title AS movie_title,
    mv.production_year AS release_year,
    CASE
        WHEN mh.level IS NOT NULL THEN 'Linked'
        ELSE 'Standalone'
    END AS movie_type,
    COALESCE(COUNT(DISTINCT ca.id) FILTER (WHERE ca.note IS NOT NULL), 0) AS num_cast_with_notes,
    SUM(CASE WHEN kw.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
    COUNT(DISTINCT mi.info) AS movie_info_count
FROM
    aka_name ak
JOIN
    cast_info ca ON ak.person_id = ca.person_id
JOIN
    aka_title mv ON ca.movie_id = mv.movie_id
LEFT JOIN
    MovieHierarchy mh ON mv.id = mh.movie_id
LEFT JOIN
    movie_keyword mk ON mv.id = mk.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN
    movie_info mi ON mv.id = mi.movie_id
GROUP BY
    ak.name, mv.title, mv.production_year, mh.level
HAVING
    (COUNT(ca.id) > 0 OR COUNT(DISTINCT mi.info) > 0)
    AND (MAX(mv.production_year) >= 2000 OR MAX(mv.production_year) IS NULL)
ORDER BY
    release_year DESC,
    num_cast_with_notes DESC,
    movie_type DESC;
