WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(*) AS actor_count
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    a.name AS actor_name,
    rt.role AS role_in_movie,
    c.name AS company_name,
    ct.kind AS company_type
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    aka_name a ON cc.subject_id = a.person_id
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    role_type rt ON cc.role_id = rt.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.actor_count DESC, 
    tm.production_year DESC;
