
WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.title, t.production_year
),
top_movies AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        ranked_movies
    WHERE 
        year_rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    STRING_AGG(a.name, ', ') AS top_actors,
    AVG(COALESCE(CAST(pi.info AS numeric), 0)) AS average_rating
FROM 
    top_movies tm
LEFT JOIN 
    cast_info ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id) 
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id 
LEFT JOIN 
    movie_info mi ON tm.production_year = mi.movie_id 
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
GROUP BY 
    tm.title, tm.production_year, tm.actor_count
HAVING 
    AVG(COALESCE(CAST(pi.info AS numeric), 0)) IS NOT NULL
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC;
