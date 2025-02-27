WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
top_years AS (
    SELECT 
        production_year, 
        AVG(total_cast) AS avg_cast_count
    FROM 
        ranked_movies
    WHERE 
        rn <= 10
    GROUP BY 
        production_year
), 
keyword_summary AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    r.title,
    r.production_year,
    r.total_cast,
    ky.keywords,
    CASE 
        WHEN r.total_cast > ts.avg_cast_count THEN 'Above Average'
        ELSE 'Below Average'
    END AS cast_performance,
    COALESCE(n.gender, 'Unknown') AS gender
FROM 
    ranked_movies r
LEFT JOIN 
    keyword_summary ky ON r.movie_id = ky.movie_id
LEFT JOIN 
    name n ON n.id IN (
        SELECT 
            ci.person_id 
        FROM 
            cast_info ci 
        WHERE 
            ci.movie_id = r.movie_id
        LIMIT 1
    )
JOIN 
    top_years ts ON r.production_year = ts.production_year
WHERE 
    r.total_cast IS NOT NULL
ORDER BY 
    r.production_year DESC, r.total_cast DESC;
