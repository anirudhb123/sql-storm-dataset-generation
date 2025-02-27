WITH ranked_movies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count, 
        STRING_AGG(DISTINCT n.name, ', ') AS actors 
    FROM 
        aka_title a 
    JOIN 
        complete_cast cc ON a.id = cc.movie_id 
    JOIN 
        cast_info c ON cc.subject_id = c.id 
    JOIN 
        aka_name n ON c.person_id = n.person_id 
    WHERE 
        a.production_year >= 2000 
    GROUP BY 
        a.id 
    ORDER BY 
        cast_count DESC 
    LIMIT 10
)
SELECT 
    rm.title, 
    rm.production_year, 
    rm.cast_count, 
    rm.actors, 
    GROUP_CONCAT(DISTINCT mk.keyword) AS keywords 
FROM 
    ranked_movies rm 
LEFT JOIN 
    movie_keyword mk ON rm.id = mk.movie_id 
GROUP BY 
    rm.title, rm.production_year, rm.cast_count, rm.actors 
ORDER BY 
    rm.cast_count DESC;
