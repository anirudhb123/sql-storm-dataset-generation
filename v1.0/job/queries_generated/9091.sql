WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
),
TopMovies AS (
    SELECT 
        r.aka_id,
        r.aka_name,
        r.movie_title,
        r.production_year
    FROM 
        RankedMovies r
    WHERE 
        r.year_rank <= 5
),
CastDetails AS (
    SELECT 
        c.movie_id,
        b.name AS actor_name,
        r.role AS role_type
    FROM 
        cast_info c
    JOIN 
        name b ON c.person_id = b.id
    JOIN 
        role_type r ON c.role_id = r.id
)
SELECT 
    tm.aka_name,
    tm.movie_title,
    tm.production_year,
    cd.actor_name,
    cd.role_type
FROM 
    TopMovies tm
JOIN 
    CastDetails cd ON tm.id = cd.movie_id
ORDER BY 
    tm.production_year DESC, tm.movie_title;
