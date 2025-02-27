
WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS actor_names
    FROM 
        title
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY 
        title.id,
        title.title,
        title.production_year
),
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        actor_names,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actor_names,
    COALESCE(STRING_AGG(DISTINCT mi.info, '; '), 'No Info') AS additional_info
FROM 
    top_movies tm
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
WHERE 
    tm.rank <= 10  
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.actor_names, tm.rank
ORDER BY 
    tm.rank;
