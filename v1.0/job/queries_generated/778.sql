WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
),
high_cast_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM
        ranked_movies rm
    WHERE 
        rm.rank <= 5
),
movie_info_with_keywords AS (
    SELECT 
        hm.title,
        hm.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM
        high_cast_movies hm
    LEFT JOIN 
        movie_keyword mk ON hm.title = (SELECT title FROM aka_title WHERE movie_id = mk.movie_id LIMIT 1)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        hm.title, hm.production_year
)

SELECT 
    m.title,
    m.production_year,
    COALESCE(string_agg(k.keyword, ', '), 'No Keywords') AS keywords,
    CASE 
        WHEN m.cast_count > 10 THEN 'Large Cast'
        WHEN m.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    high_cast_movies m
LEFT JOIN 
    movie_info mi ON mi.movie_id = (SELECT movie_id FROM aka_title WHERE title = m.title LIMIT 1)
LEFT JOIN 
    (SELECT title, production_year, keywords FROM movie_info_with_keywords) mw ON mw.title = m.title
GROUP BY 
    m.title, m.production_year, m.cast_count
ORDER BY 
    m.production_year DESC,
    m.cast_count DESC;
