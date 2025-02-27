WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS actor_count
    FROM 
        title
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.id, title.title, title.production_year
), 

actor_details AS (
    SELECT 
        aka_name.name AS actor_name,
        aka_name.person_id,
        COUNT(DISTINCT cast_info.movie_id) AS movie_count
    FROM 
        aka_name
    JOIN 
        cast_info ON aka_name.person_id = cast_info.person_id
    GROUP BY 
        aka_name.name, aka_name.person_id
),

popular_actors AS (
    SELECT 
        actor_name,
        movie_count,
        RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        actor_details
    WHERE 
        movie_count > 5
),

movie_info_total AS (
    SELECT 
        ranked_movies.movie_id,
        ranked_movies.title,
        ranked_movies.production_year,
        ranked_movies.actor_count,
        COALESCE(SUM(CASE WHEN movie_info.info_type_id = 1 THEN 1 ELSE 0 END), 0) AS awards_count,
        COALESCE(SUM(CASE WHEN movie_info.info_type_id = 2 THEN 1 ELSE 0 END), 0) AS box_office_count
    FROM 
        ranked_movies
    LEFT JOIN 
        movie_info ON ranked_movies.movie_id = movie_info.movie_id
    GROUP BY 
        ranked_movies.movie_id, ranked_movies.title, ranked_movies.production_year, ranked_movies.actor_count
)

SELECT 
    mit.movie_id,
    mit.title,
    mit.production_year,
    mit.actor_count,
    mit.awards_count,
    mit.box_office_count,
    pa.actor_name,
    pa.movie_count
FROM 
    movie_info_total mit
LEFT JOIN 
    popular_actors pa ON mit.actor_count = pa.movie_count
WHERE 
    mit.actor_count >= 10 
ORDER BY 
    mit.production_year DESC, 
    mit.actor_count DESC;
