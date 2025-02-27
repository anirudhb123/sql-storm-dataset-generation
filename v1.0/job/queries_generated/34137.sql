WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        CAST(mt.title AS VARCHAR(255)) AS full_hierarchy
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL  -- Root movies only

    UNION ALL

    SELECT
        ep.id AS movie_id,
        ep.title,
        ep.production_year,
        mh.level + 1,
        CAST(mh.full_hierarchy || ' -> ' || ep.title AS VARCHAR(255))
    FROM
        aka_title ep
    JOIN
        MovieHierarchy mh ON ep.episode_of_id = mh.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.full_hierarchy,
    COUNT(DISTINCT ci.person_id) AS total_cast_members,
    SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS main_roles_count,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order
FROM
    MovieHierarchy mh
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.person_id
GROUP BY
    mh.movie_id, mh.title, mh.production_year, mh.level, mh.full_hierarchy
HAVING
    COUNT(DISTINCT ci.person_id) > 5  -- Only movies with more than 5 cast members
ORDER BY
    mh.production_year DESC,
    total_cast_members DESC
LIMIT 10;

-- This query showcases the use of a recursive CTE to build a hierarchy of movies and their episodes.
-- It then aggregates data from the complete_cast and cast_info tables, counting cast members and roles.
-- The final results are filtered for movies with significant casts and ordered by year and member count.
