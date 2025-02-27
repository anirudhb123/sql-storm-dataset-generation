WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS role_kind,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        comp_cast_type c ON r.id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title, t.production_year, a.name, c.kind
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        role_kind,
        keyword_count,
        RANK() OVER (ORDER BY keyword_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    role_kind,
    keyword_count
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, keyword_count DESC;

