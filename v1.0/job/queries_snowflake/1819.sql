
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        r.movie_id, 
        r.title, 
        r.production_year
    FROM 
        RankedMovies r
    WHERE 
        r.rank <= 3
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MoviesWithCast AS (
    SELECT 
        t.movie_id,
        t.title,
        t.production_year,
        COALESCE(cd.actor_count, 0) AS actor_count,
        COALESCE(cd.actor_names, 'No actors') AS actor_names
    FROM 
        TopMovies t
    LEFT JOIN 
        CastDetails cd ON t.movie_id = cd.movie_id
)
SELECT 
    mwc.title,
    mwc.production_year,
    mwc.actor_count,
    mwc.actor_names,
    CASE 
        WHEN mwc.actor_count > 0 THEN 'Has Actors'
        ELSE 'No Actors'
    END AS actor_status
FROM 
    MoviesWithCast mwc
ORDER BY 
    mwc.production_year DESC, 
    mwc.actor_count DESC
LIMIT 10;
