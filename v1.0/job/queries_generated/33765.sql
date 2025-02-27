WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        array_agg(DISTINCT an.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
info_summary AS (
    SELECT 
        mi.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS total_info,
        STRING_AGG(DISTINCT mi.info, ', ') AS info_text
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
combined_results AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cs.total_cast, 0) AS total_cast,
        COALESCE(is.total_info, 0) AS total_info,
        is.info_text
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_summary cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        info_summary is ON mh.movie_id = is.movie_id
)
SELECT 
    cr.*,
    CASE 
        WHEN total_cast > 5 THEN 'Large Cast'
        WHEN total_cast BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    CASE 
        WHEN production_year IS NOT NULL THEN 
            EXTRACT(YEAR FROM CURRENT_DATE) - production_year 
        ELSE 
            NULL 
    END AS years_since_release
FROM 
    combined_results cr
WHERE 
    (total_cast > 0 OR total_info > 0)
ORDER BY 
    years_since_release DESC, total_cast DESC
LIMIT 100;
