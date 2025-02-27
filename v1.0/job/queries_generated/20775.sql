WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(MIN(mk.keyword), 'No Keywords') AS keywords,
        CAST(EXTRACT(YEAR FROM NOW()) AS INTEGER) - m.production_year AS age
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(MIN(mk.keyword), 'No Keywords') AS keywords,
        CAST(EXTRACT(YEAR FROM NOW()) AS INTEGER) - m.production_year AS age
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.movie_id
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.keywords,
        mh.age,
        RANK() OVER (PARTITION BY mh.keywords ORDER BY mh.age DESC) AS age_rank
    FROM 
        movie_hierarchy mh
    WHERE 
        mh.age IS NOT NULL
)

SELECT 
    DISTINCT r.title,
    r.keywords,
    r.age,
    CASE 
        WHEN r.age_rank <= 5 THEN 'Top Recent Movies'
        ELSE 'Older Movies'
    END AS category,
    ARRAY_AGG(DISTINCT c.name ORDER BY c.name) AS cast_members
FROM 
    ranked_movies r
LEFT JOIN 
    cast_info ci ON r.movie_id = ci.movie_id
LEFT JOIN 
    aka_name c ON ci.person_id = c.person_id
WHERE 
    r.keywords != 'No Keywords'
    AND r.age IS NOT NULL
GROUP BY 
    r.title, r.keywords, r.age, r.age_rank
HAVING 
    COUNT(c.name) > 3
ORDER BY 
    r.age DESC, r.title;

WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(NULLIF(SUBSTRING(m.title FROM 1 FOR 5), ''), 'UNTITLED') AS abbreviated_title,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id, m.title
)
SELECT 
    md.movie_id,
    md.title,
    md.abbreviated_title,
    md.keyword_count,
    md.cast_count,
    CASE 
        WHEN md.keyword_count > 5 AND md.cast_count < 10 THEN 'Underrated'
        WHEN md.keyword_count < 3 AND md.cast_count > 20 THEN 'Overrated'
        ELSE 'Average Rating'
    END AS rating_category
FROM 
    movie_details md
WHERE 
    md.cast_count IS DISTINCT FROM 0
ORDER BY 
    md.keyword_count DESC, md.title;
