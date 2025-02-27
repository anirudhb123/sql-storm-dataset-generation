WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
)
SELECT
    ak.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    COUNT(DISTINCT mk.keyword) AS num_keywords,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.level DESC) AS movie_ranking,
    STRING_AGG(DISTINCT mct.kind, ', ') FILTER (WHERE mct.kind IS NOT NULL) AS company_types,
    MIN(pi.info) AS first_info,
    MAX(pi.info) AS last_info,
    COALESCE(pi.note, 'No Note') AS note_info
FROM
    MovieHierarchy mh
LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN company_type mct ON mc.company_type_id = mct.id
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN movie_info pi ON mh.movie_id = pi.movie_id
WHERE
    mh.production_year IS NOT NULL
    AND mh.production_year > 2000
    AND (ci.note IS NULL OR ci.note NOT LIKE '%Extra%')
GROUP BY
    ak.name, mh.title, mh.production_year, pi.note
ORDER BY
    num_keywords DESC, movie_ranking ASC;
