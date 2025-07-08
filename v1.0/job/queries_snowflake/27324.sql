
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(c.id) > 5
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT i.info, ', ') WITHIN GROUP (ORDER BY i.info) AS info_details
    FROM 
        movie_info mi
    JOIN 
        info_type i ON mi.info_type_id = i.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    r.title,
    r.production_year,
    r.cast_count,
    COALESCE(mk.keywords, '[]') AS keywords,
    COALESCE(mis.info_details, 'No additional info') AS info_details
FROM 
    ranked_movies r
LEFT JOIN 
    movie_keywords mk ON r.movie_id = mk.movie_id
LEFT JOIN 
    movie_info_summary mis ON r.movie_id = mis.movie_id
ORDER BY 
    r.production_year DESC, r.cast_count DESC;
