WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        ci.movie_id
),
movie_metadata AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(mi.info, 'No Info Available') AS info,
        COUNT(DISTINCT mc.company_id) AS production_companies
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.id, mt.title, mi.info
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    ms.info,
    cs.total_cast,
    cs.cast_names,
    mh.level,
    CASE 
        WHEN ms.production_companies > 0 THEN 'Has Productions'
        ELSE 'No Productions'
    END AS production_status
FROM 
    movie_hierarchy mh
JOIN 
    movie_metadata ms ON mh.movie_id = ms.movie_id
JOIN 
    cast_summary cs ON mh.movie_id = cs.movie_id
ORDER BY 
    mh.production_year DESC, 
    mh.level, 
    cs.total_cast DESC
LIMIT 50;
