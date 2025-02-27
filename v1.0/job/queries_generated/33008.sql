WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level,
        NULL::INTEGER AS parent_id
    FROM title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM title m
    JOIN movie_link ml ON ml.linked_movie_id = m.id
    JOIN MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.level,
    COALESCE(aka.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(CASE WHEN mt.production_year IS NOT NULL THEN mt.production_year END) OVER (PARTITION BY mh.movie_id) AS avg_production_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT ck.id) FILTER (WHERE ck.kind IS NOT NULL) AS char_count
FROM MovieHierarchy mh
LEFT JOIN cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN aka_name aka ON aka.person_id = ci.person_id
LEFT JOIN movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN keyword kw ON kw.id = mk.keyword_id
LEFT JOIN complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN comp_cast_type ck ON ck.id = ci.person_role_id
GROUP BY mh.movie_id, mh.movie_title, mh.production_year, mh.level, aka.name
ORDER BY mh.level, mh.production_year DESC;
