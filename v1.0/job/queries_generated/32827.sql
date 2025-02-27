WITH RECURSIVE recent_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= (SELECT MAX(production_year) FROM aka_title) - 5
    
    UNION ALL 
    
    SELECT 
        t.id,
        t.title,
        t.production_year,
        rm.level + 1
    FROM 
        aka_title t
    INNER JOIN recent_movies rm ON t.kind_id = rm.movie_id
    WHERE 
        rm.level < 3
),

top_performers AS (
    SELECT 
        k.keyword,
        COUNT(DISTINCT m.id) AS movie_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    WHERE 
        m.production_year >= (SELECT MAX(production_year) FROM aka_title) - 5
    GROUP BY 
        k.keyword
    ORDER BY 
        movie_count DESC
    LIMIT 10
),

movie_cast AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        m.production_year >= (SELECT MAX(production_year) FROM aka_title) - 5
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(tc.movie_count, 0) AS keyword_count,
    SUM(CASE WHEN mc.actor_rank <= 3 THEN 1 ELSE 0 END) AS top_actor_count
FROM 
    recent_movies rm
LEFT JOIN 
    top_performers tc ON rm.title ILIKE '%' || tc.keyword || '%'
LEFT JOIN 
    movie_cast mc ON rm.movie_id = mc.movie_id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, tc.movie_count
ORDER BY 
    rm.production_year DESC, keyword_count DESC;
