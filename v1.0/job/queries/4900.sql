WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
    HAVING 
        COUNT(*) > 1
),
MoviesWithDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ta.actor_name,
        ta.role_count,
        (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = rm.movie_id) AS info_count,
        (SELECT STRING_AGG(DISTINCT kw.keyword, ', ') FROM movie_keyword mk JOIN keyword kw ON mk.keyword_id = kw.id WHERE mk.movie_id = rm.movie_id) AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        TopActors ta ON rm.movie_id = ta.movie_id
    WHERE 
        EXISTS (SELECT 1 FROM complete_cast cc WHERE cc.movie_id = rm.movie_id)
)
SELECT 
    mwd.movie_id,
    mwd.title,
    mwd.production_year,
    COALESCE(mwd.actor_name, 'No Actors') AS actor_name,
    COALESCE(mwd.role_count, 0) AS role_count,
    mwd.info_count,
    mwd.keywords
FROM 
    MoviesWithDetails mwd
ORDER BY 
    mwd.production_year DESC, 
    mwd.title ASC;
