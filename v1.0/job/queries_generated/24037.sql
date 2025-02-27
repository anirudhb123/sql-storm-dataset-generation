WITH ranked_titles AS (
    SELECT 
        at.title, 
        at.production_year, 
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY RANDOM()) AS rank_random
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
cast_roles AS (
    SELECT 
        ci.movie_id, 
        rt.role AS role_name, 
        COUNT(ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, 
        rt.role
),
external_links AS (
    SELECT 
        ml.movie_id, 
        COUNT(DISTINCT ml.linked_movie_id) AS linked_movies_count
    FROM 
        movie_link ml
    GROUP BY 
        ml.movie_id
),
featured_movies AS (
    SELECT 
        t.title AS movie_title,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COALESCE(el.linked_movies_count, 0) AS linked_movies,
        COALESCE(cr.role_count, 0) AS actor_with_multiple_appearances
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        cast_roles cr ON t.id = cr.movie_id
    LEFT JOIN 
        external_links el ON t.id = el.movie_id
    GROUP BY 
        t.title, el.linked_movies_count, cr.role_count
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
final_selection AS (
    SELECT 
        ft.movie_title, 
        ft.total_cast, 
        ft.linked_movies, 
        ft.actor_with_multiple_appearances,
        rt.production_year
    FROM 
        featured_movies ft
    JOIN 
        ranked_titles rt ON ft.movie_title LIKE '%' || rt.title || '%'
    WHERE 
        rt.rank_random <= 10
)
SELECT 
    fs.movie_title, 
    fs.total_cast, 
    fs.linked_movies, 
    fs.actor_with_multiple_appearances, 
    fs.production_year
FROM 
    final_selection fs
ORDER BY 
    fs.total_cast DESC, fs.linked_movies ASC, fs.actor_with_multiple_appearances DESC;
