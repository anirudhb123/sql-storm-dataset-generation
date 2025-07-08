
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER(PARTITION BY m.id ORDER BY m.production_year DESC) AS rn
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
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
        rn = 1
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
MovieSummary AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        LISTAGG(DISTINCT cd.actor_name || ' as ' || cd.role_name, ', ') WITHIN GROUP (ORDER BY cd.actor_name) AS cast
    FROM 
        TopMovies tm
    LEFT JOIN 
        CastDetails cd ON tm.movie_id = cd.movie_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.cast
FROM 
    MovieSummary ms
WHERE 
    ms.production_year IN (SELECT DISTINCT production_year FROM MovieSummary ORDER BY production_year DESC LIMIT 5)
ORDER BY 
    ms.production_year DESC;
