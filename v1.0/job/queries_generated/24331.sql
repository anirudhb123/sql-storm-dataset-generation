WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COALESCE(m2.title, 'N/A') AS linked_movie_title,
        COALESCE(m2.production_year, 'N/A') AS linked_movie_year
    FROM 
        aka_title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    LEFT JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL 

    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COALESCE(mm.title, 'N/A') AS linked_movie_title,
        COALESCE(mm.production_year, 'N/A') AS linked_movie_year
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml2 ON mh.movie_id = ml2.movie_id 
    JOIN 
        aka_title mm ON ml2.linked_movie_id = mm.id
    WHERE 
        mm.production_year IS NOT NULL
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.linked_movie_title,
        mh.linked_movie_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.movie_title) AS rank_within_year
    FROM 
        movie_hierarchy mh
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.linked_movie_title,
    rm.linked_movie_year,
    COALESCE(CAST(ri.info AS TEXT), 'No details available') AS movie_info,
    CASE 
        WHEN rm.rank_within_year <= 5 THEN 'Top 5'
        WHEN rm.rank_within_year <= 10 THEN 'Top 10'
        ELSE 'Beyond Top 10'
    END AS rank_category
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_info ri ON rm.movie_id = ri.movie_id AND ri.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot' LIMIT 1)
WHERE 
    rm.linked_movie_year IS NOT NULL 
    OR rm.linked_movie_title <> 'N/A'
ORDER BY 
    rm.production_year DESC, rm.rank_within_year;

