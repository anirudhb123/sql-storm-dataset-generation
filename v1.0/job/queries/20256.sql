WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        CASE 
            WHEN rm.production_year < 2000 THEN 'Classic'
            WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
),
TopActors AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(ci.movie_id) AS movies_played,
        RANK() OVER (ORDER BY COUNT(ci.movie_id) DESC) AS actor_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
    HAVING 
        COUNT(ci.movie_id) > 2
),
MoviesWithTopActors AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.cast_count,
        fm.era,
        ta.name AS top_actor
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        cast_info ci ON fm.movie_id = ci.movie_id
    LEFT JOIN 
        TopActors ta ON ci.person_id = ta.person_id
)
SELECT 
    mwta.title,
    mwta.production_year,
    mwta.cast_count,
    mwta.era,
    COALESCE(mwta.top_actor, 'No prominent actor') AS prominent_actor
FROM 
    MoviesWithTopActors mwta
WHERE 
    mwta.era = 'Modern'
ORDER BY 
    mwta.production_year DESC, mwta.cast_count DESC;