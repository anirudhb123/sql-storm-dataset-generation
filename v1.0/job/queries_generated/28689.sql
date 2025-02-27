WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        kt.kind AS movie_genre,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON a.movie_id = ci.movie_id
    JOIN 
        kind_type kt ON a.kind_id = kt.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        a.id, a.title, a.production_year, kt.kind
), 
FilteredMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.movie_genre,
        rm.cast_count,
        rm.cast_names
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= 2000
        AND rm.cast_count >= 5
)
SELECT 
    f.movie_title,
    f.production_year,
    f.movie_genre,
    f.cast_count,
    f.cast_names
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, 
    f.cast_count DESC;
