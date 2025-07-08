
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  

    UNION ALL

    SELECT 
        linked_movie.linked_movie_id,
        k.title AS movie_title,
        mh.level + 1
    FROM 
        movie_link linked_movie
    JOIN 
        title k ON linked_movie.movie_id = k.id
    JOIN 
        movie_hierarchy mh ON linked_movie.movie_id = mh.movie_id
    WHERE 
        mh.level < 3  
),
cast_performance AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(c.nr_order) AS avg_nr_order
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
keyword_summary AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
movie_details AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        COALESCE(cp.cast_count, 0) AS total_cast,
        COALESCE(kd.keywords, 'None') AS keyword_list,
        a.production_year
    FROM 
        aka_title a
    LEFT JOIN 
        cast_performance cp ON a.id = cp.movie_id
    LEFT JOIN 
        keyword_summary kd ON a.id = kd.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.total_cast,
    md.keyword_list,
    CASE 
        WHEN md.production_year < 2010 THEN 'Classic'
        WHEN md.production_year BETWEEN 2010 AND 2015 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_category
FROM 
    movie_details md
JOIN 
    movie_hierarchy mh ON md.movie_id = mh.movie_id
WHERE 
    md.total_cast > 5  
ORDER BY 
    md.production_year DESC,
    md.total_cast DESC;
