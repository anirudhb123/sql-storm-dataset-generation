WITH ranked_actors AS (
    SELECT 
        a.id AS actor_id,
        a.person_id,
        a.name,
        COUNT(distinct ci.movie_id) AS movie_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(distinct ci.movie_id) DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.person_id, a.name
),
top_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        total_cast DESC
    LIMIT 10
)
SELECT 
    ra.name AS actor_name,
    tm.title AS movie_title,
    tm.production_year,
    ra.movie_count,
    tm.total_cast
FROM 
    ranked_actors ra
JOIN 
    cast_info ci ON ra.person_id = ci.person_id
JOIN 
    top_movies tm ON ci.movie_id = tm.movie_id
WHERE 
    ra.rank <= 10
ORDER BY 
    tm.total_cast DESC, 
    ra.name ASC;
