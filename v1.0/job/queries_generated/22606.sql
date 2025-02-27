WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year,
        COALESCE(aka.title, 'Unknown') AS aka_title,
        1 AS depth
    FROM 
        aka_title aka
    JOIN 
        title m ON aka.movie_id = m.id
    WHERE 
        aka.production_year = m.production_year

    UNION ALL

    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year,
        COALESCE(aka.title, 'Unknown') AS aka_title,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id
    LEFT JOIN 
        aka_title aka ON aka.movie_id = m.id
    WHERE 
        mh.depth < 5  -- Limit the depth to 5 to avoid excessive recursion
),

cast_movies AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS cast_without_note
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),

movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year, 
        mh.aka_title,
        COALESCE(cm.total_cast, 0) AS total_cast,
        COALESCE(cm.cast_without_note, 0) AS cast_without_note,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.depth DESC) AS rn
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_movies cm ON mh.movie_id = cm.movie_id
)

SELECT 
    md.title,
    md.production_year,
    md.aka_title,
    md.total_cast,
    md.cast_without_note
FROM 
    movie_details md
WHERE 
    md.rn <= 10  -- Fetch the top 10 movies per production year
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC, 
    md.title;
