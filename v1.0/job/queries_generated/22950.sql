WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        NULL::integer AS parent_id,
        0 AS level,
        ARRAY[m.title] AS title_path
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.movie_id AS parent_id,
        mh.level + 1,
        mh.title_path || m.title
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rn
    FROM 
        movie_hierarchy mh
),
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        CASE 
            WHEN rm.level > 0 THEN 'Linked'
            ELSE 'Root'
        END AS movie_type,
        COALESCE(NULLIF(rm.title, ''), 'Unknown Title') AS safe_title
    FROM 
        ranked_movies rm
    WHERE 
        rm.rn <= 5
),
movie_cast_info AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS num_cast,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        filtered_movies m
    LEFT JOIN 
        cast_info c ON c.movie_id = m.movie_id
    LEFT JOIN 
        aka_name p ON p.person_id = c.person_id
    GROUP BY 
        m.movie_id
)
SELECT 
    f.movie_id,
    f.safe_title,
    f.production_year,
    f.movie_type,
    COALESCE(mci.num_cast, 0) AS num_cast,
    COALESCE(mci.cast_names, 'No Cast') AS cast_names
FROM 
    filtered_movies f
LEFT JOIN 
    movie_cast_info mci ON mci.movie_id = f.movie_id
ORDER BY 
    f.production_year DESC, f.movie_id;

