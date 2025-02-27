
WITH movie_details AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(a.name, ', ') AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
filtered_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count, 
        cast_names 
    FROM 
        movie_details
    WHERE 
        cast_count > 5
),
ranked_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count, 
        cast_names,
        RANK() OVER (ORDER BY production_year DESC, title) AS rank_position
    FROM 
        filtered_movies
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.cast_names,
    COALESCE(ct.kind, 'Unknown') AS company_type
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    rm.rank_position <= 100
ORDER BY 
    rm.production_year DESC, rm.title;
