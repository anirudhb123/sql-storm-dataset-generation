WITH ranked_titles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
filtered_titles AS (
    SELECT 
        aka_id,
        aka_name,
        movie_title,
        production_year
    FROM 
        ranked_titles
    WHERE 
        rn <= 5
),
title_keywords AS (
    SELECT 
        ft.aka_id,
        ft.aka_name,
        ft.movie_title,
        ft.production_year,
        k.keyword
    FROM 
        filtered_titles ft
    JOIN 
        movie_keyword mk ON ft.aka_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
final_results AS (
    SELECT 
        ft.aka_name,
        array_agg(DISTINCT tk.keyword) AS keywords,
        COUNT(tk.keyword) AS keyword_count,
        MIN(ft.production_year) AS first_year,
        MAX(ft.production_year) AS last_year
    FROM 
        filtered_titles ft
    LEFT JOIN 
        title_keywords tk ON ft.aka_id = tk.aka_id
    GROUP BY 
        ft.aka_name
)
SELECT 
    aka_name,
    keywords,
    keyword_count,
    first_year,
    last_year
FROM 
    final_results
ORDER BY 
    keyword_count DESC,
    aka_name;
