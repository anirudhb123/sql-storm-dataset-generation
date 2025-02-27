WITH actor_movies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        a.name IS NOT NULL
),
keyword_count AS (
    SELECT 
        m.movie_id,
        COUNT(k.id) AS keyword_cnt
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
notable_movies AS (
    SELECT 
        am.actor_name,
        am.movie_title,
        am.production_year,
        kc.keyword_cnt
    FROM 
        actor_movies am
    JOIN 
        keyword_count kc ON am.movie_rank <= 5 AND kc.movie_id = am.movie_id
    WHERE 
        am.movie_title ILIKE '%Hero%'
)

SELECT 
    actor_name,
    movie_title,
    production_year,
    keyword_cnt
FROM 
    notable_movies
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, actor_name;
