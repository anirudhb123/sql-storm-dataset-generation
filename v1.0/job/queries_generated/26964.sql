WITH MovieDetails AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        ak.name AS actor_name,
        ak.imdb_index AS actor_index,
        rt.role AS actor_role,
        mc.company_id,
        cn.name AS company_name,
        ki.keyword AS movie_keyword
    FROM 
        title
    JOIN 
        cast_info ci ON title.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        movie_companies mc ON title.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON title.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
)

SELECT 
    movie_title,
    production_year,
    STRING_AGG(DISTINCT actor_name || ' (' || actor_role || ')', ', ') AS actors,
    STRING_AGG(DISTINCT company_name, ', ') AS production_companies,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
FROM 
    MovieDetails
GROUP BY 
    movie_title, production_year
ORDER BY 
    production_year DESC, movie_title;
