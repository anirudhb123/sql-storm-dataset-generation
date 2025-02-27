
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS title,
        m.production_year AS year,
        COUNT(ka.person_id) AS actor_count
    FROM 
        aka_title AS m
    JOIN 
        cast_info AS ca ON m.id = ca.movie_id
    JOIN 
        aka_name AS ka ON ca.person_id = ka.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
keyword_analysis AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.year,
        rm.actor_count,
        ka.keywords
    FROM 
        ranked_movies AS rm
    LEFT JOIN 
        keyword_analysis AS ka ON rm.movie_id = ka.movie_id
)
SELECT 
    md.title,
    md.year,
    md.actor_count,
    COALESCE(md.keywords, 'No keywords') AS keywords
FROM 
    movie_details AS md
WHERE 
    md.year > 2000 AND 
    md.actor_count > 5
ORDER BY 
    md.year DESC, 
    md.actor_count DESC
LIMIT 10;
