
WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER(PARTITION BY title.production_year ORDER BY title.title) AS rank
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
), 
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
actor_count AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_actors
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    m.keywords,
    COALESCE(ac.num_actors, 0) AS total_actors,
    CASE 
        WHEN ac.num_actors IS NULL THEN 'No Actors'
        WHEN ac.num_actors > 10 THEN 'Large Cast'
        ELSE 'Moderate Cast'
    END AS cast_category
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keywords m ON rm.movie_id = m.movie_id
LEFT JOIN 
    actor_count ac ON rm.movie_id = ac.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title;
