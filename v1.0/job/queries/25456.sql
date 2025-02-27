
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year
    ORDER BY 
        total_cast DESC
    LIMIT 10
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.cast_names,
    mcl.linked_movie_id,
    lt.link AS relationship
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_link mcl ON rm.movie_id = mcl.movie_id
LEFT JOIN 
    link_type lt ON mcl.link_type_id = lt.id
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC;
