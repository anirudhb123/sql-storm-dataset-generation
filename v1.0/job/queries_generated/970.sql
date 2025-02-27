WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rn_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY at.id) AS actor_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info c ON at.movie_id = c.movie_id
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
top_movies AS (
    SELECT 
        title, 
        production_year, 
        actor_count 
    FROM 
        ranked_movies 
    WHERE 
        rn_year <= 5
),
movie_keywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    INNER JOIN 
        aka_title mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    COALESCE(mk.keywords_list, 'No keywords') AS keywords
FROM 
    top_movies tm
LEFT JOIN 
    movie_keywords mk ON tm.title = (SELECT at.title FROM aka_title at WHERE at.movie_id = mk.movie_id LIMIT 1)
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
