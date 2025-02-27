WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
  
    UNION ALL
  
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
),
distinct_cast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
average_cast AS (
    SELECT 
        AVG(cast_count) AS avg_cast_count
    FROM 
        distinct_cast
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(ac.cast_count, 0) AS cast_count,
        CASE 
            WHEN ac.cast_count < av.avg_cast_count THEN 'Below Average'
            WHEN ac.cast_count = av.avg_cast_count THEN 'Average'
            ELSE 'Above Average'
        END AS cast_rating
    FROM 
        aka_title m
    LEFT JOIN 
        distinct_cast ac ON m.id = ac.movie_id
    CROSS JOIN 
        average_cast av
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.cast_rating,
    string_agg(DISTINCT an.name, ', ') AS aka_names
FROM 
    movie_details md
LEFT JOIN 
    aka_name an ON an.person_id IN (
        SELECT 
            ci.person_id 
        FROM 
            cast_info ci 
        WHERE 
            ci.movie_id = md.movie_id
    )
GROUP BY 
    md.movie_id, md.title, md.production_year, md.cast_count, md.cast_rating
ORDER BY 
    md.production_year DESC, md.cast_rating, md.title;
