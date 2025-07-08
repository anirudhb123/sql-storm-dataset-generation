
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS actor_role,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, a.name, r.role
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        actor_role,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(actor_name) DESC) AS actor_count_rank
    FROM 
        MovieDetails
    GROUP BY 
        movie_title, production_year, actor_name, actor_role, keywords
)
SELECT 
    production_year,
    movie_title,
    actor_name,
    actor_role,
    keywords
FROM 
    TopMovies
WHERE 
    actor_count_rank <= 5
ORDER BY 
    production_year DESC, actor_count_rank;
