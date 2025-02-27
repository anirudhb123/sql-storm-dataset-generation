WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        0 AS level
    FROM aka_title m
    WHERE m.production_year > 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM movie_link ml
    JOIN title mt ON ml.linked_movie_id = mt.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT co.name) FILTER (WHERE co.name IS NOT NULL) AS cast_names
    FROM cast_info ci
    LEFT JOIN aka_name co ON ci.person_id = co.person_id
    GROUP BY ci.movie_id
),
movie_info_summary AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT mi.info) AS movie_infos
    FROM movie_info mc
    JOIN info_type it ON mc.info_type_id = it.id
    GROUP BY mc.movie_id
),
final_summary AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.level,
        cs.total_cast,
        cs.cast_names,
        mis.movie_infos
    FROM movie_hierarchy mh
    LEFT JOIN cast_summary cs ON mh.movie_id = cs.movie_id
    LEFT JOIN movie_info_summary mis ON mh.movie_id = mis.movie_id
)
SELECT 
    fs.movie_id,
    fs.movie_title,
    fs.production_year,
    fs.level,
    COALESCE(fs.total_cast, 0) AS total_cast,
    COALESCE(fs.cast_names, '{}') AS cast_names,
    COALESCE(fs.movie_infos, '{}') AS movie_infos
FROM final_summary fs
ORDER BY fs.production_year DESC, fs.level, fs.movie_title;
