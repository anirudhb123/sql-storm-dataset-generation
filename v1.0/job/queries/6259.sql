WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        keyword
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 10
),
CastDetails AS (
    SELECT 
        cm.movie_id, 
        p.id AS person_id, 
        p.name AS actor_name, 
        r.role AS role_name
    FROM 
        complete_cast cm
    JOIN 
        cast_info ci ON cm.movie_id = ci.movie_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.keyword, 
    cd.actor_name, 
    cd.role_name
FROM 
    TopMovies tm
JOIN 
    CastDetails cd ON tm.movie_id = cd.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title;
