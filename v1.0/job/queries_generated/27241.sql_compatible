
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS actor_role,
        ct.kind AS company_type,
        STRING_AGG(DISTINCT k.keyword, ', ') AS movie_keywords
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, a.name, r.role, ct.kind
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        actor_role,
        company_type,
        movie_keywords,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(*) DESC) AS rank
    FROM 
        MovieDetails
    GROUP BY 
        movie_title, production_year, actor_name, actor_role, company_type, movie_keywords
)
SELECT 
    production_year,
    movie_title,
    actor_name,
    actor_role,
    company_type,
    movie_keywords
FROM 
    TopMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year, rank;
