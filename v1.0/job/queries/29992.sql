WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(aka.name, ', ') AS all_aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name aka ON c.person_id = aka.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        all_aka_names,
        keywords
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000 AND cast_count > 5
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    f.all_aka_names
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, f.cast_count DESC
LIMIT 10;
