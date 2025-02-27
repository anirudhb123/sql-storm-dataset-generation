WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        0 AS level,
        m.title,
        m.production_year,
        NULL AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        mh.level + 1,
        m.title,
        m.production_year,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
cast_performance AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(role_id) AS avg_role_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cp.cast_count, 0) AS cast_count,
        COALESCE(cp.avg_role_id, 0) AS avg_role_id,
        COALESCE(cp.actors, 'No Cast') AS actors
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_performance cp ON mh.movie_id = cp.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.avg_role_id,
    md.actors,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era,
    RANK() OVER (PARTITION BY CASE 
                                WHEN md.production_year < 2000 THEN 'Classic'
                                WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
                                ELSE 'Recent'
                              END 
                     ORDER BY md.cast_count DESC) AS rank_within_era
FROM 
    movie_details md
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.cast_count, md.avg_role_id, md.actors
ORDER BY 
    movie_era, rank_within_era
LIMIT 100;
