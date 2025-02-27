WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.total_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_cast <= 5
),
ActorInfo AS (
    SELECT 
        a.name AS actor_name,
        a.id AS actor_id,
        ci.movie_id
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    WHERE 
        ci.note IS NULL
),
MoviesWithActors AS (
    SELECT 
        fm.title,
        fm.production_year,
        ARRAY_AGG(DISTINCT ai.actor_name) AS actor_names
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        ActorInfo ai ON fm.title = (SELECT t.title FROM aka_title t WHERE t.id = ai.movie_id)
    GROUP BY 
        fm.title, fm.production_year
)
SELECT 
    mw.title,
    mw.production_year,
    mw.actor_names,
    COALESCE(mo.info, 'No info available') AS additional_info
FROM 
    MoviesWithActors mw
LEFT JOIN 
    movie_info mo ON mw.title = (SELECT t.title FROM aka_title t WHERE t.production_year = mw.production_year)
WHERE 
    mw.production_year BETWEEN 2000 AND 2020
ORDER BY 
    mw.production_year DESC, 
    mw.title;
