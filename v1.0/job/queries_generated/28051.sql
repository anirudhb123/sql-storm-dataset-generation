WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        tk.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY tk.keyword) AS keyword_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword tk ON mk.keyword_id = tk.id
    WHERE 
        t.production_year >= 2000 
)

SELECT 
    an.name AS actor_name,
    rt.role AS role_name,
    rm.title AS movie_title,
    rm.production_year,
    STRING_AGG(rm.keyword, ', ' ORDER BY rm.keyword) AS keywords
FROM 
    cast_info ci
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    RankedMovies rm ON ci.movie_id = rm.movie_id
JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    rm.keyword_rank <= 5
GROUP BY 
    an.name, rt.role, rm.title, rm.production_year
ORDER BY 
    movie_title, actor_name;

This query retrieves a list of actors along with their roles and the titles of movies produced in the year 2000 or later, including the top 5 unique keywords associated with each movie. The results are grouped and ordered for clarity.
