WITH ranked_titles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY LENGTH(a.title) DESC) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
popular_actors AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) >= 5
),
title_keyword AS (
    SELECT 
        mt.movie_id,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.movie_id
)

SELECT 
    t.title AS movie_title,
    t.production_year,
    an.name AS actor_name,
    tk.keywords
FROM 
    ranked_titles t
JOIN 
    cast_info ci ON t.title_id = ci.movie_id
JOIN 
    popular_actors pa ON ci.person_id = pa.person_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    title_keyword tk ON t.title_id = tk.movie_id
WHERE 
    t.title_rank <= 3
ORDER BY 
    t.production_year DESC, LENGTH(t.title) DESC;
