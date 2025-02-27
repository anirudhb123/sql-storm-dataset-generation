WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(*) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
most_popular_titles AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        ranked_titles
    WHERE 
        rank = 1
),
actor_movie_info AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    GROUP BY 
        a.name, t.title, t.production_year
)
SELECT 
    p.actor_name,
    p.movie_title,
    p.production_year,
    COALESCE(pm.role_count, 0) AS role_count
FROM 
    most_popular_titles mpt
LEFT JOIN 
    actor_movie_info p ON p.movie_title = mpt.title AND p.production_year = mpt.production_year
LEFT JOIN 
    actor_movie_info pm ON pm.movie_title = p.movie_title AND pm.production_year = p.production_year
ORDER BY 
    mpt.production_year DESC, 
    p.role_count DESC;