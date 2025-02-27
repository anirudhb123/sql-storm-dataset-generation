
WITH RECURSIVE top_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.movie_id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(c.person_id) >= 5
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
movie_info_data AS (
    SELECT 
        mi.movie_id, 
        STRING_AGG(mi.info, ', ') AS info_details
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info IN ('Plot', 'Awards')
    GROUP BY 
        mi.movie_id
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    mk.keywords,
    COALESCE(mid.info_details, 'No details available') AS movie_info
FROM 
    top_movies tm
LEFT JOIN 
    movie_keywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    movie_info_data mid ON tm.movie_id = mid.movie_id
WHERE 
    tm.production_year BETWEEN 1990 AND 2023
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
