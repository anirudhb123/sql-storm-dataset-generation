WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        K.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(ci.person_id) DESC) as rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword K ON mk.keyword_id = K.id
    GROUP BY 
        t.id, t.title, t.production_year, K.keyword
),
filtered_titles AS (
    SELECT 
        title_id,
        title,
        production_year,
        cast_count,
        keyword 
    FROM 
        ranked_titles 
    WHERE 
        rank = 1
)
SELECT 
    ft.title,
    ft.production_year,
    ft.cast_count,
    ak.name AS actor_name,
    ak.imdb_index AS actor_imdb_index,
    ft.keyword
FROM 
    filtered_titles ft
JOIN 
    cast_info ci ON ft.title_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    ft.production_year >= 2000 
ORDER BY 
    ft.production_year DESC, ft.cast_count DESC;
