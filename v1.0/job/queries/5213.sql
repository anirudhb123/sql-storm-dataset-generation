WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        t.id, t.title, t.production_year
), TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        company_count, 
        keyword_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title, 
    tm.production_year, 
    a.name AS actor_name, 
    r.role AS actor_role
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON cc.movie_id = tm.movie_id
JOIN 
    cast_info ci ON ci.id = cc.subject_id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    role_type r ON r.id = ci.role_id
ORDER BY 
    tm.production_year DESC, 
    tm.company_count DESC;
