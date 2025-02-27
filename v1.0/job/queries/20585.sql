WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        movie_id, 
        episode_of_id, 
        season_nr,
        1 AS hierarchy_level
    FROM 
        aka_title 
    WHERE 
        episode_of_id IS NOT NULL

    UNION ALL

    SELECT 
        mt.movie_id, 
        mt.episode_of_id, 
        mt.season_nr,
        mh.hierarchy_level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh 
    ON 
        mt.id = mh.episode_of_id
), 

cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS total_cast,
        SUM(CASE WHEN ci.note IS NULL OR ci.note = '' THEN 1 ELSE 0 END) AS unnamed_cast 
    FROM 
        cast_info ci 
    GROUP BY 
        ci.movie_id
),

keyword_summary AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords 
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id 
    GROUP BY 
        mk.movie_id
)

SELECT 
    mt.title,  
    COALESCE(ks.keywords, 'No Keywords') AS keywords,
    mh.hierarchy_level,
    cs.total_cast,
    cs.unnamed_cast,
    CASE 
        WHEN cs.total_cast = 0 THEN 'No Cast Information'
        ELSE 'Has Cast Information'
    END AS cast_info_status
FROM 
    aka_title mt
LEFT JOIN 
    movie_hierarchy mh ON mt.id = mh.movie_id
LEFT JOIN 
    cast_summary cs ON mt.id = cs.movie_id
LEFT JOIN 
    keyword_summary ks ON mt.id = ks.movie_id
WHERE 
    (mh.hierarchy_level IS NOT NULL OR cs.total_cast > 0)
    AND (mt.production_year >= 2000 OR mt.title LIKE '%Remake%')
ORDER BY 
    mt.production_year DESC, 
    mh.hierarchy_level, 
    mt.title;