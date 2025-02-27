WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(COUNT(DISTINCT ci.person_id), 0) AS cast_count,
        COALESCE(STRING_AGG(DISTINCT p.name, ', '), '') AS cast_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.movie_id
    LEFT JOIN 
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
FilteredMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.cast_names,
        CASE 
            WHEN md.cast_count > 5 THEN 'Large Cast'
            WHEN md.cast_count BETWEEN 3 AND 5 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END AS cast_size
    FROM 
        MovieDetails md
    WHERE 
        md.production_year >= 2000 
        AND md.cast_count IS NOT NULL
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    f.cast_names,
    f.cast_size,
    COALESCE(p.keywords, 'No Keywords') AS keywords
FROM 
    FilteredMovies f
LEFT JOIN 
    PopularKeywords p ON f.movie_id = p.movie_id
ORDER BY 
    f.production_year DESC, f.cast_count DESC;
