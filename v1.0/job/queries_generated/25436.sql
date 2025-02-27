WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
ranked_movies_with_score AS (
    SELECT 
        rm.*,
        RANK() OVER (ORDER BY actor_count DESC, production_year DESC) AS movie_rank
    FROM 
        ranked_movies rm
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.actor_names,
    r.actor_count,
    r.keywords,
    r.movie_rank
FROM 
    ranked_movies_with_score r
WHERE 
    r.actor_count > 1
    AND r.movie_rank <= 50
ORDER BY 
    r.movie_rank;

