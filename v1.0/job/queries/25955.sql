WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS director_name,
        r.role AS actor_role,
        COUNT(c.id) AS num_actors,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id AND cn.country_code = 'USA'
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id AND a.name_pcode_cf IS NOT NULL
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, a.name, r.role
),
TopMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY num_actors DESC) AS actor_rank
    FROM 
        RankedMovies
)
SELECT 
    title,
    production_year,
    director_name,
    actor_role,
    num_actors
FROM 
    TopMovies
WHERE 
    actor_rank <= 10
ORDER BY 
    num_actors DESC;
