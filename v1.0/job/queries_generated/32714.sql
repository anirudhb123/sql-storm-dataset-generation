WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        h.level + 1
    FROM
        movie_link ml
        JOIN aka_title m ON ml.linked_movie_id = m.id
        JOIN movie_hierarchy h ON ml.movie_id = h.movie_id
)
SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    AVG(CASE WHEN cast.nr_order IS NOT NULL THEN cast.nr_order ELSE 0 END) AS avg_order,
    MAX(CASE WHEN ci.role_id IS NOT NULL THEN r.role END) AS main_role,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY AVG(CASE WHEN cast.nr_order IS NOT NULL THEN cast.nr_order ELSE 0 END) DESC) AS rank
FROM
    aka_name a
    JOIN cast_info cast ON a.person_id = cast.person_id
    JOIN aka_title t ON cast.movie_id = t.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN role_type r ON cast.role_id = r.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
WHERE
    t.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY
    a.name,
    t.title,
    t.production_year
HAVING
    COUNT(DISTINCT mk.keyword) > 1
    AND MIN(cn.country_code) IS NOT NULL
ORDER BY
    rank;
