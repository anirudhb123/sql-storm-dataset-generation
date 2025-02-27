WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(m2.title, 'N/A') AS parent_title,
        0 AS level
    FROM title m
    LEFT JOIN movie_link ml ON m.id = ml.movie_id
    LEFT JOIN title m2 ON ml.linked_movie_id = m2.id
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.title AS parent_title,
        mh.level + 1
    FROM title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    mh.movie_id,
    mh.title AS movie_title,
    mh.production_year,
    mh.parent_title,
    mh.level,
    COALESCE(ai.name, 'Unknown Actor') AS lead_actor,
    CASE
        WHEN mh.production_year IS NULL THEN 'Year Unknown'
        ELSE CAST(mh.production_year AS TEXT)
    END AS production_year_str,
    COUNT(DISTINCT kc.keyword) FILTER (WHERE kc.keyword IS NOT NULL) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank_in_level
FROM MovieHierarchy mh
LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN aka_name ai ON cc.subject_id = ai.person_id
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN keyword kc ON mk.keyword_id = kc.id
GROUP BY mh.movie_id, mh.title, mh.production_year, mh.parent_title, mh.level, ai.name
ORDER BY mh.level, production_year_str DESC, keyword_count DESC;
