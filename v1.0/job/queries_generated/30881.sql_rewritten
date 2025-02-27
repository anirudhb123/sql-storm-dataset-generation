WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id 
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
),

cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS full_cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id 
    GROUP BY 
        ci.movie_id
),

keyword_summary AS (
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
        m.id AS movie_id,
        m.title,
        m.production_year,
        cs.cast_count,
        cs.full_cast_names,
        ks.keywords
    FROM 
        aka_title m
    LEFT JOIN 
        cast_summary cs ON m.id = cs.movie_id
    LEFT JOIN 
        keyword_summary ks ON m.id = ks.movie_id 
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.cast_count, 0) AS total_cast,
    md.full_cast_names,
    md.keywords,
    CASE 
        WHEN md.production_year IS NULL THEN 'Unknown' 
        ELSE CONCAT('Year: ', md.production_year) 
    END AS year_info,
    ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.title) AS row_num,
    COUNT(1) OVER (PARTITION BY md.production_year) AS total_movies_in_year
FROM 
    movie_details md
WHERE 
    md.production_year IS NOT NULL
ORDER BY 
    md.production_year DESC,
    md.title;