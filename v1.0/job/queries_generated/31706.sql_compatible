
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        NULL AS parent_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        ep.id,
        ep.title,
        ep.production_year,
        mh.id AS parent_id,
        mh.level + 1
    FROM 
        aka_title ep
    JOIN 
        movie_hierarchy mh ON ep.episode_of_id = mh.id
),
cast_stats AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS total_cast,
        COUNT(DISTINCT ci.person_id) AS unique_cast,
        ARRAY_AGG(DISTINCT ak.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        mh.id AS movie_id,
        mh.title,
        mh.production_year,
        cs.total_cast,
        cs.unique_cast,
        COALESCE(mk.keywords, 'None') AS keywords,
        mh.parent_id,
        mh.level
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_stats cs ON mh.id = cs.movie_id
    LEFT JOIN 
        movie_keywords mk ON mh.id = mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.level,
    md.total_cast,
    md.unique_cast,
    md.keywords,
    (SELECT COUNT(*) 
     FROM movie_companies mc 
     WHERE mc.movie_id = md.movie_id 
     AND mc.company_type_id IS NOT NULL) AS company_count,
    (SELECT 
        COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = md.movie_id 
     AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Awards')) AS award_info_count,
    CASE 
        WHEN md.level > 1 THEN 'Is Part Of Series'
        ELSE 'Standalone Movie'
    END AS series_status
FROM 
    movie_details md
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
