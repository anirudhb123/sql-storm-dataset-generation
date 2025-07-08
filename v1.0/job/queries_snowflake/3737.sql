
WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank,
        COUNT(c.person_id) AS actor_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
high_actor_movies AS (
    SELECT 
        movie_title,
        production_year,
        actor_count 
    FROM 
        ranked_movies 
    WHERE 
        rank <= 5
),
movie_keywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    hm.movie_title,
    hm.production_year,
    hm.actor_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = a.movie_id AND mi.info LIKE '%Oscar%') AS oscar_count
FROM 
    high_actor_movies hm
LEFT JOIN 
    aka_title a ON hm.movie_title = a.title AND hm.production_year = a.production_year
LEFT JOIN 
    movie_keywords mk ON a.movie_id = mk.movie_id
ORDER BY 
    hm.production_year DESC, 
    hm.actor_count DESC;
