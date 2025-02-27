
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),

keyword_movies AS (
    SELECT 
        m.movie_id,
        k.keyword
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%action%'
),

movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.actor_names,
        COALESCE(STRING_AGG(DISTINCT km.keyword, ', '), 'No Keywords') AS keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        keyword_movies km ON rm.movie_id = km.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.cast_count, rm.actor_names
)

SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.actor_names,
    md.keywords
FROM 
    movie_details md
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC
LIMIT 10;
