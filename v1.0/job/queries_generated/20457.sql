WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieInfo AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role,
        COALESCE(SUM(mnk.id), 0) AS keyword_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mnk ON mnk.movie_id = c.movie_id
    JOIN 
        role_type r ON r.id = c.role_id
    GROUP BY 
        c.movie_id, a.name, r.role
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        amis.actor_name,
        amis.role,
        amis.keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorMovieInfo amis ON rm.movie_id = amis.movie_id
    WHERE 
        (rm.year_rank <= 5 OR amis.keyword_count > 3)
),
DistinctKeywords AS (
    SELECT DISTINCT 
        mk.keyword
    FROM 
        movie_keyword mk
    JOIN 
        FilteredMovies fm ON fm.movie_id = mk.movie_id
    WHERE 
        mk.keyword IS NOT NULL
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_name,
    fm.role,
    CASE 
        WHEN fm.keyword_count IS NOT NULL THEN fm.keyword_count
        ELSE -1 
    END AS keyword_count,
    STRING_AGG(dk.keyword, ', ') AS keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    DistinctKeywords dk ON fm.movie_id IN (SELECT movie_id FROM movie_keyword WHERE keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE 'A%'))
GROUP BY 
    fm.title, fm.production_year, fm.actor_name, fm.role, fm.keyword_count
ORDER BY 
    fm.production_year DESC, fm.title;
