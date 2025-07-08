
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title et
    JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
),
movie_cast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
movie_info_avg AS (
    SELECT 
        movie_id,
        AVG(LENGTH(mi.info)) AS avg_info_length
    FROM 
        movie_info mi
    GROUP BY 
        movie_id
),
final_report AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(mc.total_cast, 0) AS total_cast,
        COALESCE(mia.avg_info_length, 0) AS avg_info_length,
        mh.level,
        CASE 
            WHEN mh.production_year < 2000 THEN 'Classic'
            WHEN mh.production_year >= 2000 AND mh.production_year < 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_cast mc ON mh.movie_id = mc.movie_id
    LEFT JOIN 
        movie_info_avg mia ON mh.movie_id = mia.movie_id
)
SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY era ORDER BY production_year DESC) AS rank_within_era
FROM 
    final_report
WHERE 
    total_cast > (SELECT AVG(total_cast) FROM movie_cast) 
ORDER BY 
    era, production_year DESC;
