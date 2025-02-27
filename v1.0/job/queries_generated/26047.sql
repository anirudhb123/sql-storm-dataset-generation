WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year
    ORDER BY 
        cast_count DESC
    LIMIT 10
)

SELECT 
    rm.movie_id, 
    rm.title, 
    rm.production_year, 
    rm.cast_count, 
    rm.actors,
    COALESCE(AVG(m.info_length), 0) AS average_info_length
FROM 
    ranked_movies rm
LEFT JOIN (
    SELECT 
        mi.movie_id, 
        AVG(LENGTH(mi.info)) AS info_length
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
) m ON rm.movie_id = m.movie_id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, rm.cast_count, rm.actors
ORDER BY 
    rm.cast_count DESC;
