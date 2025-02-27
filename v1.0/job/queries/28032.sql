WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.actor_count,
        rm.actor_names,
        RANK() OVER (ORDER BY rm.actor_count DESC) AS movie_rank
    FROM 
        ranked_movies rm
    WHERE 
        rm.production_year >= 2000
)

SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.actor_count,
    tm.actor_names,
    i.info AS additional_info,
    k.keyword AS movie_keyword
FROM 
    top_movies tm
LEFT JOIN 
    movie_info i ON tm.movie_id = i.movie_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    tm.movie_rank <= 10
ORDER BY 
    tm.actor_count DESC, 
    tm.production_year DESC;
