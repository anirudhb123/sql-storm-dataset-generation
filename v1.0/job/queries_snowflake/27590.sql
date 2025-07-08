
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
filtered_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        cast_names,
        keywords,
        RANK() OVER (ORDER BY production_year DESC, cast_count DESC) AS movie_rank
    FROM 
        ranked_movies
    WHERE 
        production_year >= 2000 AND cast_count > 5
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    f.cast_names,
    f.keywords,
    f.movie_rank
FROM 
    filtered_movies f
ORDER BY 
    f.movie_rank
LIMIT 10;
