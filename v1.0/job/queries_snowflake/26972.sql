
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
top_ranked_titles AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        ranked_titles
    WHERE 
        rank <= 5
),
movie_cast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
final_result AS (
    SELECT 
        tt.production_year,
        tt.title,
        mc.actor_name,
        mc.role_name
    FROM 
        top_ranked_titles tt
    LEFT JOIN 
        movie_cast mc ON tt.title_id = mc.movie_id
)
SELECT 
    production_year,
    title,
    LISTAGG(CONCAT(actor_name, ' as ', role_name), '; ') WITHIN GROUP (ORDER BY actor_name) AS actors
FROM 
    final_result
GROUP BY 
    production_year, title
ORDER BY 
    production_year DESC, title;
