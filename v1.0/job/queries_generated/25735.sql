WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS akas,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        akas,
        cast_count,
        RANK() OVER (ORDER BY production_year DESC, cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    fm.title,
    fm.production_year,
    fm.akas,
    fm.cast_count,
    ci.note AS cast_note,
    ci.nr_order AS cast_order
FROM 
    FilteredMovies fm
LEFT JOIN 
    cast_info ci ON fm.movie_id = ci.movie_id
WHERE 
    fm.cast_count > 5 
ORDER BY 
    fm.rank
LIMIT 20;
