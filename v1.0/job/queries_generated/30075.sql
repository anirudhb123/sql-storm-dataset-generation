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
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT cc.person_id) AS total_cast_members,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    SUM(CASE WHEN pi.info_type_id = 1 THEN 1 ELSE 0 END) AS personal_notes_count,
    MAX(CASE WHEN pi.info_type_id = 2 THEN pi.info END) AS director_note
FROM
    aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN aka_title at ON ci.movie_id = at.id
LEFT JOIN person_info pi ON ak.person_id = pi.person_id
LEFT JOIN movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
JOIN MovieHierarchy mh ON at.id = mh.movie_id
WHERE
    ak.name IS NOT NULL
    AND (at.production_year IS NOT NULL OR at.production_year >= 1990)
GROUP BY
    ak.name,
    at.title,
    at.production_year
HAVING
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY
    at.production_year DESC,
    total_cast_members DESC;
