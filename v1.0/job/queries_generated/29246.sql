WITH actor_movie AS (
    SELECT 
        c.person_id,
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        c.person_id, t.title, t.production_year, a.name
),
rating_summary AS (
    SELECT 
        actor_movie.actor_name, 
        COUNT(DISTINCT actor_movie.movie_title) AS num_movies,
        AVG(length(actor_movie.movie_title)) AS avg_title_length,
        SUM(keyword_count) AS total_keywords
    FROM 
        actor_movie
    GROUP BY 
        actor_movie.actor_name
)
SELECT 
    r.actor_name,
    r.num_movies,
    r.avg_title_length,
    r.total_keywords,
    p.info AS additional_info
FROM 
    rating_summary r
LEFT JOIN 
    person_info p ON p.person_id = (SELECT id FROM aka_name WHERE name = r.actor_name LIMIT 1)
WHERE 
    r.num_movies > 5
ORDER BY 
    r.total_keywords DESC, 
    r.num_movies DESC;
