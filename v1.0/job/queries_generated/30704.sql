WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 1  -- Assuming 1 is the code for movies

    UNION ALL

    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.movie_id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
movie_cast AS (
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
movie_info_data AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(CASE WHEN it.info = 'Budget' THEN mi.info ELSE NULL END, ', ') AS budget,
        STRING_AGG(CASE WHEN it.info = 'Genre' THEN mi.info ELSE NULL END, ', ') AS genre
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    mh.title,
    mh.production_year,
    COALESCE(mc.total_cast, 0) AS total_cast,
    mc.cast_names,
    mi.budget,
    mi.genre,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mc.total_cast DESC) AS rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_cast mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_info_data mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.depth = 1
AND 
    (mh.production_year > 2000 OR mi.budget IS NOT NULL)
ORDER BY 
    mh.production_year DESC, rank
LIMIT 50;
