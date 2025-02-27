WITH ranked_movies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
    AND 
        a.name IS NOT NULL
), movie_keyword_ranking AS (
    SELECT 
        rm.actor_name,
        rm.movie_title,
        rm.production_year,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_title = (SELECT title FROM aka_title WHERE movie_id = mk.movie_id)
    GROUP BY 
        rm.actor_name, 
        rm.movie_title, 
        rm.production_year
), filtered_ranking AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        keyword_count,
        RANK() OVER (ORDER BY keyword_count DESC) AS keyword_rank
    FROM 
        movie_keyword_ranking
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    keyword_count,
    keyword_rank
FROM 
    filtered_ranking
WHERE 
    keyword_rank <= 10
ORDER BY 
    production_year DESC, 
    keyword_count DESC;
