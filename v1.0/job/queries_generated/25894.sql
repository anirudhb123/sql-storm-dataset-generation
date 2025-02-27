WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', a.name_pcode_nf, ')'), ', ') AS actors,
        AVG(mv.rating) AS average_rating
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_info mv ON m.id = mv.movie_id AND mv.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        m.id
),
top_movies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY average_rating DESC, cast_count DESC) AS movie_rank
    FROM 
        ranked_movies
)
SELECT 
    tm.movie_rank,
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    tm.actors
FROM 
    top_movies tm
WHERE 
    tm.movie_rank <= 10
ORDER BY 
    tm.average_rating DESC;

This query ranks movies based on their average rating and number of cast members, retrieves details about the top 10 movies, and aggregates the actors' names associated with each movie for string processing benchmarking.
