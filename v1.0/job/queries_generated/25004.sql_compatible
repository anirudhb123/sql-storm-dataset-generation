
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS actor_role,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COALESCE(c.name, 'Unknown') AS company_name,
        c.country_code AS company_country,
        COUNT(DISTINCT ci.person_id) AS total_cast_members
    FROM 
        aka_title t 
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title, t.production_year, a.name, r.role, c.name, c.country_code
),
RankedMovies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY total_cast_members DESC) AS rank
    FROM 
        MovieDetails md
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    actor_role,
    keywords,
    company_name,
    company_country,
    total_cast_members
FROM 
    RankedMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year, total_cast_members DESC;
