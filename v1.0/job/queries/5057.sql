WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        m.name AS company_name,
        r.role,
        COUNT(ci.person_id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, m.name, r.role
),
TopMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rn
    FROM 
        RankedMovies
)
SELECT 
    title,
    production_year,
    company_name,
    role,
    actor_count
FROM 
    TopMovies
WHERE 
    rn <= 5
ORDER BY 
    production_year DESC, actor_count DESC;
