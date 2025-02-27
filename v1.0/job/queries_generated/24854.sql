WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::text AS parent_title,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.title AS parent_title,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
cast_counts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
keyword_movies AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_info_details AS (
    SELECT 
        mi.movie_id,
        MAX(mi.info) AS notes
    FROM 
        movie_info mi
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Synopsis')
    GROUP BY 
        mi.movie_id
),
combined_results AS (
    SELECT 
        mv.movie_id,
        mv.title,
        mv.production_year,
        mh.parent_title,
        COALESCE(km.keywords, 'No Keywords') AS keywords,
        COALESCE(ci.total_cast, 0) AS total_cast,
        COALESCE(mid.notes, 'No Synopsis available') AS synopsis,
        ROW_NUMBER() OVER (ORDER BY mv.production_year DESC, mv.title) AS row_num
    FROM 
        movie_hierarchy mv
    LEFT JOIN 
        cast_counts ci ON mv.movie_id = ci.movie_id
    LEFT JOIN 
        keyword_movies km ON mv.movie_id = km.movie_id
    LEFT JOIN 
        movie_info_details mid ON mv.movie_id = mid.movie_id
)
SELECT 
    cr.movie_id,
    cr.title,
    cr.production_year,
    cr.parent_title,
    cr.keywords AS movie_keywords,
    cr.total_cast,
    cr.synopsis,
    CASE 
        WHEN cr.total_cast > 5 THEN 'Highly Casted'
        WHEN cr.total_cast BETWEEN 3 AND 5 THEN 'Moderately Casted'
        ELSE 'Low Cast'
    END AS cast_category,
    CASE 
        WHEN cr.production_year IS NULL THEN 'Unknown Year'
        ELSE 'Released'
    END AS release_status,
    CASE 
        WHEN cr.synopsis IS NULL OR cr.synopsis = 'No Synopsis available' THEN 'Synopsis not provided'
        ELSE 'Synopsis available'
    END AS synopsis_status
FROM 
    combined_results cr
WHERE 
    cr.row_num <= 100
ORDER BY 
    cr.production_year DESC, 
    cr.total_cast DESC NULLS LAST;
