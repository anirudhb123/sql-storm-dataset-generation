WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || et.title AS VARCHAR(255)) AS path
    FROM aka_title et
    JOIN MovieHierarchy mh ON et.episode_of_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.path,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    AVG(CASE WHEN mi.info_type_id IS NOT NULL THEN LENGTH(mi.info) ELSE 0 END) AS avg_info_length
FROM MovieHierarchy mh
LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN movie_info mi ON mh.movie_id = mi.movie_id
WHERE mh.production_year BETWEEN 2000 AND 2023
  AND (mh.title ILIKE '%Adventure%' OR mh.title ILIKE '%Drama%')
GROUP BY 
    mh.movie_id, 
    mh.title, 
    mh.production_year, 
    mh.level, 
    mh.path
ORDER BY 
    mh.production_year DESC, 
    cast_count DESC
LIMIT 100;
