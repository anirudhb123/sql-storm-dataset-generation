
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
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
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
filtered_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cd.cast_count,
        cd.cast_names
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_details cd ON mh.movie_id = cd.movie_id
    WHERE 
        cd.cast_count IS NOT NULL OR cd.cast_count >= 3 
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.cast_count, 0) AS total_cast,
    CASE 
        WHEN fm.cast_count IS NOT NULL AND fm.cast_count > 5 THEN 'Large Cast'
        WHEN fm.cast_count IS NOT NULL AND fm.cast_count BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    LISTAGG(fm.cast_names, '; ') WITHIN GROUP (ORDER BY fm.cast_names) AS actors
FROM 
    filtered_movies fm
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, fm.cast_count
ORDER BY 
    fm.production_year DESC, 
    total_cast DESC
LIMIT 100;
