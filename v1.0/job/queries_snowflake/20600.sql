
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(pt.title, 'N/A') AS parent_title,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        aka_title pt ON m.episode_of_id = pt.id

    UNION ALL

    SELECT 
        cm.id,
        cm.title,
        cm.production_year,
        mh.title AS parent_title,
        mh.level + 1
    FROM 
        aka_title cm
    JOIN 
        movie_hierarchy mh ON cm.episode_of_id = mh.movie_id
),
cast_aggregates AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Notable Info' THEN mi.info END) AS notable_info,
        COUNT(DISTINCT it.info) AS total_info_types
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.parent_title,
    COALESCE(ca.total_cast, 0) AS total_cast,
    COALESCE(ca.cast_names, 'No Cast') AS cast_names,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    COALESCE(ks.keyword_list, 'No Keywords') AS keyword_list,
    COALESCE(mi.notable_info, 'No Notable Info') AS notable_info,
    mi.total_info_types
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_aggregates ca ON mh.movie_id = ca.movie_id
LEFT JOIN 
    keyword_summary ks ON mh.movie_id = ks.movie_id
LEFT JOIN 
    movie_info_summary mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.production_year IS NOT NULL
    AND mh.level <= 3
    AND ((mh.production_year % 2 = 0 AND ks.keyword_count > 2) OR mh.production_year % 2 = 1)
ORDER BY 
    mh.production_year DESC, 
    total_cast DESC, 
    mh.title;
