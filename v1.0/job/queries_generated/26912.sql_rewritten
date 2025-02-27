WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        STRING_AGG(DISTINCT b.name, ', ') AS cast_names,
        COUNT(DISTINCT c.id) AS total_cast_members
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name b ON c.person_id = b.person_id
    WHERE 
        a.kind_id IN (1, 2)  
    GROUP BY 
        a.id, a.title, a.production_year
    ORDER BY 
        a.production_year DESC
    LIMIT 10
)

SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_names,
    rm.total_cast_members,
    m.info AS movie_summary,
    COALESCE(k.keywords, 'None') AS movie_keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_info m ON rm.production_year = m.movie_id
LEFT JOIN 
    (SELECT 
         movie_id,
         STRING_AGG(keyword, ', ') AS keywords
     FROM 
         movie_keyword mk
     JOIN 
         keyword k ON mk.keyword_id = k.id
     GROUP BY 
         movie_id) k ON rm.production_year = k.movie_id
ORDER BY 
    rm.production_year DESC, rm.total_cast_members DESC;