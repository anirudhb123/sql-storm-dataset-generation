WITH actor_movie_details AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        r.role AS role_name,
        kc.count_keywords
    FROM aka_name AS a
    JOIN cast_info AS c ON a.person_id = c.person_id
    JOIN title AS t ON c.movie_id = t.id
    JOIN role_type AS r ON c.role_id = r.id
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(keyword_id) AS count_keywords
        FROM movie_keyword
        GROUP BY movie_id
    ) AS kc ON t.id = kc.movie_id
    WHERE t.production_year >= 2000
      AND a.name NOT LIKE '%test%'
      AND a.name IS NOT NULL
),
unique_movies AS (
    SELECT 
        DISTINCT movie_title,
        production_year,
        COUNT(DISTINCT actor_id) AS unique_actors
    FROM actor_movie_details
    GROUP BY movie_title, production_year
),
final_summary AS (
    SELECT 
        movie_title,
        production_year,
        unique_actors,
        RANK() OVER (ORDER BY unique_actors DESC) AS rank
    FROM unique_movies
)

SELECT
    movie_title,
    production_year,
    unique_actors,
    rank
FROM final_summary
WHERE rank <= 10
ORDER BY rank;

This query aims to benchmark string processing by extracting detailed information about actors and the movies they participated in, while also aggregating keyword counts for each movie. It retrieves the top 10 movies from the year 2000 onwards based on the number of unique actors, showcasing the complexities of joins, string processing operations, and advanced SQL features like CTEs and window functions.
