WITH ranked_titles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    INNER JOIN 
        cast_info c ON a.person_id = c.person_id
    INNER JOIN 
        aka_title t ON c.movie_id = t.movie_id
),
filtered_titles AS (
    SELECT 
        actor_name, 
        movie_title, 
        production_year
    FROM 
        ranked_titles
    WHERE 
        title_rank <= 5
),
title_keywords AS (
    SELECT 
        mt.movie_id,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM 
        movie_keyword mt
    INNER JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
final_selection AS (
    SELECT 
        ft.actor_name,
        ft.movie_title,
        ft.production_year,
        tk.keywords
    FROM 
        filtered_titles ft
    LEFT JOIN 
        title_keywords tk ON ft.movie_title = (SELECT title FROM aka_title WHERE id = ft.title_id)
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    COALESCE(keywords, 'No keywords') AS keywords
FROM 
    final_selection
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, actor_name;
