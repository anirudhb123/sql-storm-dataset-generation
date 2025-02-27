WITH RECURSIVE MovieHierarchy AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level,
        CAST(t.title AS VARCHAR(255)) AS path
    FROM
        aka_title t
    WHERE
        t.episode_of_id IS NULL

    UNION ALL

    SELECT
        ea.id AS movie_id,
        ea.title,
        ea.production_year,
        mh.level + 1 AS level,
        CAST(mh.path || ' -> ' || ea.title AS VARCHAR(255)) AS path
    FROM
        aka_title ea
    JOIN
        MovieHierarchy mh ON ea.episode_of_id = mh.movie_id
)
SELECT
    mh.path,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    SUM(CASE WHEN o.kind = 'Production' THEN 1 ELSE 0 END) AS production_company_count,
    SUM(CASE WHEN o.kind = 'Distribution' THEN 1 ELSE 0 END) AS distribution_company_count
FROM
    MovieHierarchy mh
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    company_name o ON mc.company_id = o.id
LEFT JOIN
    aka_name ak ON c.person_id = ak.person_id
WHERE
    mh.production_year >= 2000
GROUP BY
    mh.path, mh.production_year
HAVING
    COUNT(DISTINCT c.person_id) > 5
ORDER BY
    mh.production_year DESC, actor_count DESC;
