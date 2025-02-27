WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.kind AS company_kind,
        a.name AS actor_name,
        r.role AS role_type,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, c.kind, a.name, r.role
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        company_kind, 
        actor_name, 
        role_type, 
        keyword_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    production_year, 
    title, 
    actor_name, 
    role_type, 
    company_kind, 
    keyword_count
FROM 
    TopMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year, keyword_count DESC;
