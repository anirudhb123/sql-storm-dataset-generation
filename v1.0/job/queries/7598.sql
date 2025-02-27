WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(c.person_id) AS actor_count,
        AVG(mi.info::float) AS avg_movie_info_length
    FROM 
        title m 
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id 
    WHERE 
        m.production_year >= 2000 
    GROUP BY 
        m.id
), 
top_movies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year, 
        actor_count, 
        avg_movie_info_length,
        RANK() OVER (ORDER BY actor_count DESC, avg_movie_info_length DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.actor_count,
    tm.avg_movie_info_length,
    p.name AS top_actor
FROM 
    top_movies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name p ON c.person_id = p.person_id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.actor_count DESC, tm.avg_movie_info_length DESC;
