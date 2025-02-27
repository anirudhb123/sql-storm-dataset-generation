WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT a.name) AS actor_names,
        ROW_NUMBER() OVER (ORDER BY COUNT(c.person_id) DESC, t.production_year DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),

movie_info_details AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
        ARRAY_AGG(DISTINCT i.info) AS info_details
    FROM 
        ranked_movies m
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        movie_info i ON m.movie_id = i.movie_id
    GROUP BY 
        m.movie_id
)

SELECT 
    rm.rank,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rmd.keywords,
    rmd.info_details
FROM 
    ranked_movies rm
JOIN 
    movie_info_details rmd ON rm.movie_id = rmd.movie_id
WHERE 
    rm.cast_count > 5
ORDER BY 
    rm.rank
LIMIT 10;
