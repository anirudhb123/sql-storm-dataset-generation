WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        RANK() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.kind_id
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
),
Actors AS (
    SELECT 
        ak.name AS actor_name,
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name, ci.movie_id
),
MoviesWithActors AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.kind_id,
        ARRAY_AGG(DISTINCT a.actor_name) AS actors,
        COALESCE(SUM(a.role_count), 0) AS total_roles
    FROM 
        TopMovies tm
    LEFT JOIN 
        Actors a ON tm.title = a.movie_id
    GROUP BY 
        tm.title, tm.production_year, tm.kind_id
)
SELECT 
    mw.title,
    mw.production_year,
    kt.kind AS movie_kind,
    mw.actors,
    mw.total_roles
FROM 
    MoviesWithActors mw 
LEFT JOIN 
    kind_type kt ON mw.kind_id = kt.id
WHERE 
    mw.total_roles > 0
ORDER BY 
    mw.production_year DESC,
    mw.title;
