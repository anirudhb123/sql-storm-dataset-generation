
WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        t.production_year,
        COUNT(c.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS co_actors,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank,
        t.id AS movie_id
    FROM 
        title AS t
    JOIN 
        aka_title AS a ON t.id = a.movie_id
    JOIN 
        cast_info AS c ON t.id = c.movie_id
    JOIN 
        aka_name AS ak ON ak.person_id = c.person_id
    WHERE 
        a.kind_id IS NOT NULL 
        AND t.production_year >= 2000
    GROUP BY 
        a.title, t.production_year, t.id
),
top_movies AS (
    SELECT 
        movie_title,
        production_year,
        actor_count,
        co_actors,
        movie_id
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
)

SELECT 
    tm.movie_title,
    tm.production_year,
    tm.actor_count,
    tm.co_actors,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
FROM 
    top_movies AS tm
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = tm.movie_id
LEFT JOIN 
    keyword AS k ON k.id = mk.keyword_id
GROUP BY 
    tm.movie_title, tm.production_year, tm.actor_count, tm.co_actors
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
