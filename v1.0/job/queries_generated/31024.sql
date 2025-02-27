WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
        
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS total_keywords
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cs.total_cast,
        cs.cast_names,
        ks.total_keywords,
        CASE 
            WHEN mh.level > 1 THEN 'Sequel/Related'
            ELSE 'Standalone'
        END AS movie_type
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_summary cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        keyword_summary ks ON mh.movie_id = ks.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.cast_names,
    md.total_keywords,
    md.movie_type,
    COALESCE(md.total_keywords, 0) AS keyword_count
FROM 
    movie_details md
WHERE 
    (md.production_year = 2021 OR md.production_year = 2022)
    AND md.movie_type = 'Sequel/Related'
ORDER BY 
    md.production_year DESC, md.total_cast DESC;
