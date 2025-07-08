WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT CONCAT(a.name, ' as ', r.role)) AS cast_list,
        RANK() OVER (ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        t.id, t.title, t.production_year
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_list,
    COALESCE(mi.info, 'No info') AS movie_info
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_info mi ON rm.movie_id = mi.movie_id 
WHERE 
    rm.year_rank <= 10 AND
    (mi.info IS NULL OR mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Summary'))
ORDER BY 
    rm.production_year DESC;
