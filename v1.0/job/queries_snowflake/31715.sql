
WITH RECURSIVE movie_hierarchy AS (
    
    SELECT 
        m.id AS movie_id,
        m.title,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        mh.level + 1 AS level
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
cast_agg AS (
    
    SELECT 
        ci.movie_id, 
        LISTAGG(DISTINCT an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS cast_names,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
movie_info_detail AS (
    
    SELECT 
        mt.movie_id,
        LISTAGG(CASE WHEN mi.info_type_id = 1 THEN mi.info END, '; ') WITHIN GROUP (ORDER BY mi.info) AS genre_info,
        LISTAGG(CASE WHEN mi.info_type_id = 2 THEN mi.info END, '; ') WITHIN GROUP (ORDER BY mi.info) AS plot_info
    FROM 
        movie_info mi
    JOIN 
        aka_title mt ON mi.movie_id = mt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    mh.title AS Movie_Title,
    mh.level AS Episode_Level,
    ca.cast_names AS Cast_Names,
    ca.cast_count AS Number_of_Actors,
    mid.genre_info AS Genres,
    mid.plot_info AS Plot_Details
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_agg ca ON mh.movie_id = ca.movie_id
LEFT JOIN 
    movie_info_detail mid ON mh.movie_id = mid.movie_id
WHERE 
    mh.level = 0  
    AND (mid.genre_info IS NOT NULL OR mid.plot_info IS NOT NULL)
ORDER BY 
    mh.title;
