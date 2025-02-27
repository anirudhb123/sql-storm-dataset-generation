WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year, 
        COUNT(ci.id) AS cast_count,
        STRING_AGG(a.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.movie_title, 
        rm.production_year, 
        rm.cast_count,
        rm.actor_names
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year BETWEEN 2000 AND 2023
        AND rm.cast_count > 5
),
MovieInfo AS (
    SELECT 
        fm.movie_id, 
        mi.info AS additional_info
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_info mi ON fm.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%award%')
),
FinalOutput AS (
    SELECT 
        fm.movie_id, 
        fm.movie_title, 
        fm.production_year, 
        fm.cast_count, 
        fm.actor_names, 
        mi.additional_info
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        MovieInfo mi ON fm.movie_id = mi.movie_id
)
SELECT 
    fo.movie_id,
    fo.movie_title,
    fo.production_year,
    fo.cast_count,
    fo.actor_names,
    COALESCE(fo.additional_info, 'No Additional Info') AS additional_info
FROM 
    FinalOutput fo
ORDER BY 
    fo.production_year DESC, 
    fo.cast_count DESC;
