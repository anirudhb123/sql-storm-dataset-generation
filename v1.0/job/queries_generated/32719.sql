WITH RECURSIVE MovieHierarchy AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM
        aka_title t
    WHERE
        t.production_year >= 2000
    UNION ALL
    SELECT
        t.id AS movie_id,
        CONCAT(mh.title, ' -> ', t.title) AS title,
        t.production_year,
        mh.level + 1
    FROM
        aka_title t
    INNER JOIN
        movie_link ml ON t.id = ml.linked_movie_id
    INNER JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(c.name, 'Unknown') AS company_name,
    COUNT(DISTINCT ci.person_id) AS num_cast_members,
    SUM(CASE WHEN ci.role_id = rt.id THEN 1 ELSE 0 END) AS num_roles,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
FROM
    MovieHierarchy mh
LEFT JOIN
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    company_name c ON mc.company_id = c.id
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN
    role_type rt ON ci.role_id = rt.id
LEFT JOIN
    aka_name ak ON ci.person_id = ak.person_id
WHERE
    mh.level = 1
GROUP BY
    mh.movie_id, mh.title, mh.production_year, company_name
ORDER BY
    num_cast_members DESC, mh.production_year ASC;
