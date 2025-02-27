WITH  
    ranked_movies AS (
        SELECT 
            at.title, 
            at.production_year, 
            ak.name AS actor_name, 
            ct.kind AS role_type
        FROM 
            aka_title at
        JOIN 
            cast_info ci ON at.id = ci.movie_id
        JOIN 
            aka_name ak ON ci.person_id = ak.person_id
        JOIN 
            role_type ct ON ci.role_id = ct.id
    ),
    final_benchmark AS (
        SELECT 
            title, 
            production_year, 
            actor_name, 
            role_type,
            ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY title) AS ranking
        FROM 
            ranked_movies
    )
SELECT 
    title, 
    production_year, 
    actor_name, 
    role_type
FROM 
    final_benchmark 
WHERE 
    ranking <= 10
ORDER BY 
    production_year DESC, title;
