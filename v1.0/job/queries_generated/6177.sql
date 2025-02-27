WITH ranked_actors AS (
    SELECT 
        a.person_id, 
        a.name, 
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
), 
popular_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
), 
complete_details AS (
    SELECT 
        t.title,
        t.production_year,
        ra.name AS actor_name,
        ra.movie_count
    FROM 
        popular_movies t
    JOIN 
        ranked_actors ra ON t.movie_id IN (
            SELECT 
                ci.movie_id 
            FROM 
                cast_info ci 
            WHERE 
                ci.person_id = ra.person_id
        )
    ORDER BY 
        t.production_year DESC
)
SELECT 
    cd.title,
    cd.production_year,
    cd.actor_name,
    cd.movie_count
FROM 
    complete_details cd
WHERE 
    cd.movie_count > 2
ORDER BY 
    cd.production_year DESC, cd.actor_name;
