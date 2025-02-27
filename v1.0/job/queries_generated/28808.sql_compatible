
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        rm.keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= 2000 
        AND rm.cast_count >= 5
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    f.cast_names,
    COALESCE(f.keywords, 'No keywords available') AS keywords_summary
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, 
    f.cast_count DESC;
