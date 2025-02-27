WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.id
    WHERE 
        mh.depth < 5 
),
movie_cast AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        complete_cast mc
    JOIN 
        cast_info ci ON mc.subject_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        mc.movie_id
),
movie_info_details AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    WHERE 
        mi.note IS NOT NULL
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COALESCE(mci.total_cast, 0) AS total_cast,
    COALESCE(mci.cast_names, 'No Cast') AS cast_names,
    COALESCE(mii.info_details, 'No Info') AS info_details,
    CASE 
        WHEN mh.production_year < 2000 THEN 'Classic' 
        ELSE 'Modern' 
    END AS era,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.movie_title ASC) AS movie_rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_cast mci ON mh.movie_id = mci.movie_id
LEFT JOIN 
    movie_info_details mii ON mh.movie_id = mii.movie_id
WHERE 
    mh.production_year >= 1980
ORDER BY 
    mh.production_year DESC, mh.movie_title;