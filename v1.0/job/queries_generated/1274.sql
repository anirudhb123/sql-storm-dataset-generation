WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
movie_keywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
important_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        mk.keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_keywords mk ON rm.id = mk.movie_id
    WHERE 
        rm.year_rank <= 5
)

SELECT 
    im.title,
    im.production_year,
    im.cast_count,
    COALESCE(im.keywords, 'No Keywords') AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies
FROM 
    important_movies im
LEFT JOIN 
    movie_companies mc ON im.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    im.title, im.production_year, im.cast_count
ORDER BY 
    im.production_year DESC, im.cast_count DESC;
