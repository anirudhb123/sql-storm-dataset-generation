WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        c.movie_id,
        STRING_AGG(a.name, ', ') AS actors,
        SUM(CASE WHEN r.role = 'lead' THEN 1 ELSE 0 END) AS lead_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
movie_info_details AS (
    SELECT 
        m.movie_id,
        MAX(CASE WHEN it.info = 'rating' THEN m.info END) AS rating,
        MAX(CASE WHEN it.info = 'summary' THEN m.info END) AS summary
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cd.actors,
    cd.lead_count,
    mid.rating,
    mid.summary
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_details cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    movie_info_details mid ON rm.movie_id = mid.movie_id
WHERE 
    rm.title_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
