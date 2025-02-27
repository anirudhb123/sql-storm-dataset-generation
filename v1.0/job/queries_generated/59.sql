WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movies AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.person_id) AS actor_count,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
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
    r.movie_id,
    r.title,
    r.production_year,
    am.actor_name,
    am.actor_count,
    am.noted_roles,
    mk.keywords
FROM 
    ranked_movies r
LEFT JOIN 
    actor_movies am ON r.movie_id = am.movie_id
LEFT JOIN 
    movie_keywords mk ON r.movie_id = mk.movie_id
WHERE 
    r.rank <= 5
ORDER BY 
    r.production_year DESC, r.title;
