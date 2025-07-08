WITH movie_actors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    GROUP BY 
        a.id, a.name
),
noteworthy_movies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT m.keyword_id) AS keyword_count
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword m ON at.id = m.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
    HAVING 
        COUNT(DISTINCT m.keyword_id) >= 3
),
top_movies AS (
    SELECT 
        nm.movie_id,
        nm.title,
        nm.production_year,
        nm.keyword_count,
        ROW_NUMBER() OVER (ORDER BY nm.keyword_count DESC, nm.production_year DESC) AS movie_rank
    FROM 
        noteworthy_movies nm
)
SELECT 
    ma.actor_id,
    ma.actor_name,
    tm.title AS movie_title,
    tm.production_year,
    tm.keyword_count
FROM 
    movie_actors ma
JOIN 
    cast_info ci ON ma.actor_id = ci.person_id
JOIN 
    top_movies tm ON ci.movie_id = tm.movie_id
WHERE 
    tm.movie_rank <= 10
ORDER BY 
    ma.actor_name, tm.production_year DESC;
