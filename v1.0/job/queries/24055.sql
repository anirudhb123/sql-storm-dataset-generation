WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id DESC) AS rn
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(ci.id) AS total_cast,
        COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_with_notes
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalOutput AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        md.cast_with_notes,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        CASE 
            WHEN md.total_cast = 0 THEN 'No Cast' 
            WHEN md.cast_with_notes > 0 THEN 'Notable Cast' 
            ELSE 'Average Cast' 
        END AS cast_significance
    FROM 
        MovieDetails md
    LEFT JOIN 
        MovieKeywords mk ON md.movie_id = mk.movie_id
)
SELECT 
    fo.movie_id,
    fo.title,
    fo.production_year,
    fo.total_cast,
    fo.cast_with_notes,
    fo.keywords,
    fo.cast_significance
FROM 
    FinalOutput fo
WHERE 
    fo.production_year > 2000
    AND (fo.total_cast > 5 OR fo.cast_significance = 'Notable Cast')
ORDER BY 
    fo.production_year DESC, 
    fo.total_cast DESC
FETCH FIRST 50 ROWS ONLY;
