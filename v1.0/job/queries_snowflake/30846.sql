
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL AS parent_id
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1,
        mh.movie_id
    FROM
        aka_title e
        JOIN MovieHierarchy mh ON e.episode_of_id = mh.movie_id
)

SELECT
    ak.name AS actor_name,
    mt.title AS movie_title,
    mh.level AS episode_level,
    2024 - mt.production_year AS years_since_release,
    COUNT(DISTINCT mi.info) AS info_count,
    LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS company_names
FROM
    cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN aka_title mt ON ci.movie_id = mt.id
    LEFT JOIN MovieHierarchy mh ON mt.id = mh.movie_id
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN movie_info mi ON mt.id = mi.movie_id
WHERE
    mt.production_year BETWEEN 2000 AND 2024 
    AND ak.name IS NOT NULL
GROUP BY
    ak.name, mt.title, mh.level, mt.production_year
HAVING
    COUNT(DISTINCT c.name) > 0
ORDER BY
    years_since_release DESC, ak.name;
