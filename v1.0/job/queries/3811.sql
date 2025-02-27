WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
keyword_counts AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
summary AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        (CASE 
            WHEN rm.cast_count > 5 THEN 'Ensemble Cast'
            WHEN rm.cast_count BETWEEN 3 AND 5 THEN 'Moderate Cast'
            ELSE 'Small Cast'
        END) AS cast_size
    FROM 
        ranked_movies rm
    LEFT JOIN 
        keyword_counts kc ON rm.title = (SELECT title FROM aka_title WHERE id = kc.movie_id)
    WHERE 
        rm.rn <= 10 
)
SELECT 
    s.title,
    s.production_year,
    s.cast_count,
    s.keyword_count,
    s.cast_size
FROM 
    summary s
WHERE 
    s.production_year >= 2000 
ORDER BY 
    s.production_year DESC, s.cast_count DESC;
