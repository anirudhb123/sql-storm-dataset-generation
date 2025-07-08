WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        k.keyword AS movie_keyword,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id, k.keyword 
),

director_movies AS (
    SELECT 
        ci.movie_id,
        ci.person_id AS director_id
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        rt.role = 'Director'
),

actor_movies AS (
    SELECT 
        ci.movie_id,
        ci.person_id AS actor_id
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        rt.role = 'Actor'
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.kind_id,
    md.movie_keyword,
    md.cast_count,
    (SELECT COUNT(*) FROM director_movies dm WHERE dm.movie_id = md.movie_id) AS director_count,
    (SELECT COUNT(*) FROM actor_movies am WHERE am.movie_id = md.movie_id) AS actor_count
FROM 
    movie_details md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC,
    md.title;
