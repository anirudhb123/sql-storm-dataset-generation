
WITH ranked_movies AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.title, m.production_year
),
complex_movie_data AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(ROUND(AVG(t.rating), 2), 0) AS avg_rating,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = rm.title AND production_year = rm.production_year LIMIT 1)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON rm.title = mi.info AND rm.production_year = (SELECT production_year FROM aka_title WHERE title = rm.title LIMIT 1)
    LEFT JOIN 
        (SELECT movie_id, AVG(CAST(info AS DECIMAL)) AS rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating') GROUP BY movie_id) AS t ON t.movie_id = (SELECT id FROM aka_title WHERE title = rm.title LIMIT 1)
    WHERE 
        rm.rn <= 5
    GROUP BY 
        rm.title, rm.production_year
)
SELECT 
    cmd.title,
    cmd.production_year,
    cmd.avg_rating,
    cmd.keywords
FROM 
    complex_movie_data cmd
WHERE 
    cmd.avg_rating > 0
ORDER BY 
    cmd.production_year DESC, cmd.avg_rating DESC;
