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
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.production_year >= 2000
),
average_cast AS (
    SELECT 
        c.movie_id,
        AVG(c.nr_order) AS avg_order
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
high_avg_cast AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        a.avg_order,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY a.avg_order DESC) AS rn
    FROM 
        movie_hierarchy m
    JOIN average_cast a ON m.movie_id = a.movie_id
),
top_movies AS (
    SELECT 
        *
    FROM 
        high_avg_cast
    WHERE 
        rn <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.avg_order,
    COUNT(c.id) AS cast_count,
    COALESCE(SUM(mk.id), 0) AS keyword_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    CASE 
        WHEN COUNT(c.id) > 10 THEN 'Large Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    top_movies tm
LEFT JOIN 
    cast_info c ON tm.movie_id = c.movie_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    tm.title, tm.production_year, tm.avg_order
ORDER BY 
    tm.avg_order DESC;
