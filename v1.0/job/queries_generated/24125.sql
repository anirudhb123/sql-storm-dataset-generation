WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        0 AS parent_id
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM
        movie_link ml
    JOIN aka_title at ON at.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    akn.name AS actor_name,
    mt.title AS movie_title,
    COUNT(DISTINCT mc.company_id) FILTER (WHERE cct.kind = 'Production') AS production_companies,
    AVG(CASE WHEN mi.info_type_id = 3 THEN LENGTH(mi.info) END) AS avg_movie_length,
    MAX(CASE WHEN rt.role LIKE 'Lead%' THEN rt.role END) AS lead_role,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    mh.level AS hierarchy_level
FROM
    aka_name akn
JOIN cast_info ci ON akn.person_id = ci.person_id
JOIN aka_title mt ON ci.movie_id = mt.id
LEFT JOIN movie_companies mc ON mc.movie_id = mt.id
LEFT JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN comp_cast_type cct ON ci.role_id = cct.id
LEFT JOIN movie_info mi ON mt.id = mi.movie_id
LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
LEFT JOIN role_type rt ON ci.person_role_id = rt.id
JOIN movie_hierarchy mh ON mh.movie_id = mt.id
WHERE
    mt.production_year > 2000
    AND ci.nr_order IS NOT NULL
    AND (cn.country_code IS NULL OR cn.country_code <> 'USA')
GROUP BY
    akn.name, mt.title, mh.level
HAVING
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY
    avg_movie_length DESC NULLS LAST,
    actor_name ASC,
    movie_title ASC;
