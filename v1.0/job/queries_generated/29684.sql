WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name ORDER BY ak.name) AS unique_aka_names
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id
),
ranked_names AS (
    SELECT 
        c.id AS cast_id,
        n.name,
        n.gender,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY n.name) AS name_rank
    FROM 
        cast_info c
    JOIN 
        aka_name n ON c.person_id = n.person_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.unique_aka_names,
    rn.name,
    rn.gender,
    rn.name_rank
FROM 
    ranked_movies rm
LEFT JOIN 
    ranked_names rn ON rm.movie_id = rn.cast_id
WHERE 
    rm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    rm.production_year DESC,
    rm.cast_count DESC;
