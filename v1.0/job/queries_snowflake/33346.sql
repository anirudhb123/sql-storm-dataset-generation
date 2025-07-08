
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM
        aka_title m
    WHERE
        m.episode_of_id IS NULL

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1 AS depth,
        CAST(CONCAT(mh.path, ' > ', m.title) AS VARCHAR(255)) AS path
    FROM
        aka_title m
        JOIN movie_hierarchy mh ON m.episode_of_id = mh.movie_id
)
SELECT
    mh.path,
    mh.depth,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    AVG(m.production_year) AS avg_production_year,
    LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS known_as,
    SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS role_count,
    ROW_NUMBER() OVER (PARTITION BY mh.depth ORDER BY AVG(m.production_year) DESC) AS row_rank
FROM
    movie_hierarchy mh
    LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN aka_title m ON mh.movie_id = m.id
WHERE
    mh.depth < 5
GROUP BY
    mh.path, mh.depth, m.production_year
HAVING
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY
    mh.depth, total_cast DESC;
