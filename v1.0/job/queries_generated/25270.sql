WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS actor_count
    FROM title
    JOIN cast_info ON title.id = cast_info.movie_id
    WHERE title.production_year >= 2000
    GROUP BY title.id
),
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rank
    FROM ranked_movies
    WHERE actor_count >= 5
),
complete_movie_details AS (
    SELECT 
        top_movies.movie_id,
        top_movies.title,
        top_movies.production_year,
        top_movies.actor_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords
    FROM top_movies
    LEFT JOIN cast_info ON top_movies.movie_id = cast_info.movie_id
    LEFT JOIN aka_name ON cast_info.person_id = aka_name.person_id
    LEFT JOIN movie_keyword ON top_movies.movie_id = movie_keyword.movie_id
    LEFT JOIN keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY top_movies.movie_id, top_movies.title, top_movies.production_year, top_movies.actor_count
)
SELECT 
    complete_movie_details.title,
    complete_movie_details.production_year,
    complete_movie_details.actor_count,
    complete_movie_details.actor_names,
    complete_movie_details.keywords
FROM complete_movie_details
ORDER BY complete_movie_details.actor_count DESC, complete_movie_details.production_year DESC
LIMIT 10;
