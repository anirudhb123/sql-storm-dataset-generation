WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        r.role AS actor_role,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        a.production_year >= 2000
        AND k.keyword IS NOT NULL
    GROUP BY 
        a.title, a.production_year, k.keyword, c.name, r.role
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        movie_keyword,
        company_name,
        actor_role,
        actor_count,
        ROW_NUMBER() OVER (PARTITION BY movie_keyword ORDER BY actor_count DESC) AS rn
    FROM 
        RankedMovies
)
SELECT 
    movie_title,
    production_year,
    movie_keyword,
    company_name,
    actor_role,
    actor_count
FROM 
    TopMovies
WHERE 
    rn <= 3
ORDER BY 
    movie_keyword, actor_count DESC;
