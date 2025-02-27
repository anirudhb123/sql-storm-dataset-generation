WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        r.role,
        COUNT(c.id) AS cast_count
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        a.id, a.title, a.production_year, r.role
),
top_movies AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY role ORDER BY cast_count DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    t.title,
    t.production_year,
    t.role,
    t.cast_count
FROM 
    top_movies t
WHERE 
    t.rank <= 5
ORDER BY 
    t.role, 
    t.cast_count DESC;