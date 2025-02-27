WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    WHERE
        mh.level < 3
)

SELECT
    DISTINCT
    ak.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS runtime_infos,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY mh.production_year DESC) as row_num
FROM
    MovieHierarchy mh
JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
WHERE
    ak.name IS NOT NULL
    AND mh.production_year IS NOT NULL
    AND (mi.note IS NULL OR mi.info IS NOT NULL)
GROUP BY
    ak.name, mh.movie_id, mh.title, mh.production_year
HAVING
    COUNT(DISTINCT mc.company_id) > 1
    AND SUM(CASE WHEN mi.info_type_id = 3 THEN 1 ELSE 0 END) < 5
ORDER BY
    mh.production_year DESC,
    ak.name;
