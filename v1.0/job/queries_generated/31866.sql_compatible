
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.depth < 3
),
movie_cast AS (
    SELECT 
        c.movie_id,
        COUNT(*) AS cast_count,
        STRING_AGG(a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
movie_info_aggregated AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mc.cast_count, 0) AS cast_count,
        COALESCE(mc.cast_names, 'No Cast') AS cast_names,
        COUNT(DISTINCT mw.keyword_id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_cast mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mw ON m.id = mw.movie_id
    GROUP BY 
        m.id, m.title, m.production_year, mc.cast_count, mc.cast_names
),
selected_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ma.cast_count,
        ma.cast_names,
        DENSE_RANK() OVER (ORDER BY mh.depth DESC, ma.cast_count DESC) AS movie_rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_info_aggregated ma ON mh.movie_id = ma.movie_id
)
SELECT 
    sm.title,
    sm.production_year,
    sm.cast_count,
    sm.cast_names,
    sm.movie_rank,
    CASE 
        WHEN sm.cast_count > 0 THEN 'Featured'
        ELSE 'No Cast'
    END AS cast_status
FROM 
    selected_movies sm
WHERE 
    sm.movie_rank <= 10
ORDER BY 
    sm.movie_rank;
