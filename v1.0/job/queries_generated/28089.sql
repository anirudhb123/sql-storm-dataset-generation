WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        t.kind_id, 
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') ASaka_names
    FROM 
        aka_title ak 
    JOIN 
        title t ON ak.movie_id = t.id 
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id 
    GROUP BY 
        t.id
), FilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        kind_id, 
        cast_count,
        aka_names 
    FROM 
        RankedMovies 
    WHERE 
        production_year >= 2000 
        AND cast_count > 5
), MovieDetails AS (
    SELECT 
        f.title,
        f.production_year,
        f.cast_count,
        kt.kind AS movie_type,
        ARRAY_AGG(DISTINCT ci.note) AS role_notes
    FROM 
        FilteredMovies f
    JOIN 
        kind_type kt ON f.kind_id = kt.id
    LEFT JOIN 
        cast_info ci ON f.title = ci.movie_id
    GROUP BY 
        f.title, f.production_year, f.cast_count, kt.kind
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.movie_type,
    md.role_notes,
    md.aka_names
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
