
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS ranking
    FROM 
        aka_title t 
    WHERE 
        t.production_year IS NOT NULL
), 
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(DISTINCT cc.id) AS cast_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS cast_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name cn ON ci.person_id = cn.person_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
), 
FilteredMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.cast_names
    FROM 
        MovieDetails md
    WHERE 
        md.cast_count > 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(mk.keyword_id::text, ', ') AS keywords
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.cast_names,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieKeywords mk ON fm.movie_id = mk.movie_id
ORDER BY 
    fm.production_year DESC, fm.title;
