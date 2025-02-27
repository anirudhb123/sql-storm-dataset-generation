WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_within_year
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
), 
top_movies AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        ranked_movies
    WHERE 
        rank_within_year <= 5
), 
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    top_movies tm
LEFT JOIN 
    movie_keywords mk ON tm.movie_id = mk.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
