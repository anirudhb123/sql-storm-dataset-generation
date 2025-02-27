WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS movie_rank,
        ARRAY_AGG(DISTINCT ak.name) AS actors
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT inf.info, ', ') AS info
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info LIKE '%Award%'
    GROUP BY 
        mi.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actors,
        mi.info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieInfo mi ON rm.title = mi.movie_id
    WHERE 
        rm.movie_rank <= 3
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actors,
    COALESCE(fm.info, 'No awards info available') AS awards_info
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, fm.title;
