WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        c.name AS company_name,
        r.role AS actor_role,
        ak.name AS actor_name,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name c ON c.id = mc.company_id
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info ci ON ci.id = cc.subject_id
    JOIN 
        role_type r ON r.id = ci.role_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year, c.name, r.role, ak.name
),
RankedMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    title,
    production_year,
    company_name,
    actor_role,
    actor_name,
    keyword_count
FROM 
    RankedMovies
WHERE 
    rank <= 5;
