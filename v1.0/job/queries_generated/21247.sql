WITH ranked_titles AS (
    SELECT 
        t.title,
        t.production_year,
        t.id AS title_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_type
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
),
title_keywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
film_info AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(k.keywords, 'No Keywords') AS keywords,
        COALESCE(c.actor_name, 'Unknown Actor') AS lead_actor,
        t.production_year
    FROM 
        aka_title m
    LEFT JOIN 
        title_keywords k ON m.id = k.movie_id
    LEFT JOIN 
        cast_details c ON m.id = c.movie_id AND c.nr_order = 1
    JOIN 
        ranked_titles rt ON m.id = rt.title_id
    WHERE 
        rt.year_rank <= 5
)
SELECT 
    f.movie_id,
    f.title,
    f.keywords,
    f.lead_actor,
    f.production_year,
    CASE 
        WHEN f.production_year < 2000 THEN 'Classic'
        WHEN f.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    film_info f
ORDER BY 
    f.production_year DESC, 
    f.title;

