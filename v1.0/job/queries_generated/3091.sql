WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
actor_movie_count AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        ranked_movies rm ON ci.movie_id = rm.id
    GROUP BY 
        ci.person_id
),
latest_movies AS (
    SELECT 
        rm.title,
        rm.production_year
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank = 1
),
highest_actor_movie_count AS (
    SELECT 
        ac.person_id
    FROM 
        actor_movie_count ac
    WHERE 
        ac.movie_count = (SELECT MAX(movie_count) FROM actor_movie_count)
)
SELECT 
    a.name,
    lm.title,
    lm.production_year,
    COALESCE(ci.note, 'No role assigned') AS role_note,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = lm.id) AS info_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    latest_movies lm ON ci.movie_id = lm.id
WHERE 
    EXISTS (SELECT 1 FROM highest_actor_movie_count hac WHERE hac.person_id = a.person_id)
ORDER BY 
    lm.production_year DESC, a.name ASC;
