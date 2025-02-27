WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        r.role AS actor_role,
        c.note AS cast_note,
        k.keyword AS movie_keyword,
        cmp.name AS company_name
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies m_c ON t.id = m_c.movie_id
    LEFT JOIN 
        company_name cmp ON m_c.company_id = cmp.id
)

SELECT 
    movie_title,
    production_year,
    actor_name,
    actor_role,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_name, ', ') AS production_companies,
    COUNT(DISTINCT actor_name) AS total_actors
FROM 
    MovieDetails
GROUP BY 
    movie_title, production_year, actor_name, actor_role
ORDER BY 
    production_year DESC, movie_title;
