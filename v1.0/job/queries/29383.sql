WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
movie_keyword_info AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        rm.actor_names,
        COALESCE(mki.keywords, 'No Keywords') AS keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_keyword_info mki ON rm.movie_id = mki.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    md.actor_names,
    md.keywords
FROM 
    movie_details md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.actor_count DESC, md.production_year ASC
LIMIT 10;
