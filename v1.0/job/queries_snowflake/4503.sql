
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
    GROUP BY 
        ci.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mc.actor_count,
        mc.actor_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCast mc ON rm.movie_id = mc.movie_id
    WHERE 
        rm.title_rank <= 5 
        AND rm.production_year > 2000
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.actor_count, 0) AS actor_count,
    fm.actor_names,
    CASE 
        WHEN fm.actor_count IS NULL THEN 'No Actors'
        ELSE 'Has Actors'
    END AS actor_status
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, fm.title;
