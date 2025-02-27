WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        r.role,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year > 2000
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
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
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_name,
    rm.role AS actor_role,
    rm.actor_rank,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.actor_rank <= 3
ORDER BY 
    rm.production_year DESC, rm.movie_id;
