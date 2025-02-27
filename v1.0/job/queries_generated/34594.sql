WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        a.name AS actor_name,
        1 AS depth
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id IS NOT NULL
  
    UNION ALL
  
    SELECT 
        c.id AS cast_id,
        c.person_id,
        a.name AS actor_name,
        ah.depth + 1
    FROM 
        cast_info c
    JOIN 
        actor_hierarchy ah ON c.movie_id = ah.cast_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id IS NOT NULL
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        array_agg(DISTINCT a.actor_name) AS cast_names,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        m.id
),
top_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_names,
        md.keyword_count,
        ROW_NUMBER() OVER (ORDER BY md.keyword_count DESC) AS rnk
    FROM 
        movie_details md
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_names,
    COALESCE(NULLIF(tm.keyword_count, 0), 'No Keywords') AS keywords_info,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = tm.movie_id) AS complete_cast_count
FROM 
    top_movies tm
WHERE 
    tm.rnk <= 10 
ORDER BY 
    tm.production_year DESC,
    tm.keyword_count DESC;
