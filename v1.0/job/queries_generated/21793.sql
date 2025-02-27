WITH RankedMovies AS (
    SELECT 
        T.id AS movie_id,
        T.title,
        T.production_year,
        ROW_NUMBER() OVER (PARTITION BY T.production_year ORDER BY T.id) AS year_rank,
        COUNT(CAST(CAST(CI.id AS TEXT) AS INT)) OVER(PARTITION BY T.production_year) AS movie_count
    FROM 
        aka_title T
    LEFT JOIN 
        movie_keyword MK ON T.id = MK.movie_id
    LEFT JOIN 
        keyword K ON MK.keyword_id = K.id
    WHERE 
        K.keyword LIKE '%drama%'
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        year_rank,
        movie_count
    FROM 
        RankedMovies
    WHERE 
        movie_count > 1
    AND 
        year_rank <= 5
),
MovieDetails AS (
    SELECT 
        FM.movie_id,
        FM.title,
        FM.production_year,
        COALESCE(SUM(CASE WHEN CI.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count,
        MAX(COALESCE(TI.info, 'No Information')) AS movie_info
    FROM 
        FilteredMovies FM
    LEFT JOIN 
        complete_cast CC ON FM.movie_id = CC.movie_id
    LEFT JOIN 
        movie_info MI ON FM.movie_id = MI.movie_id
    LEFT JOIN 
        info_type TI ON MI.info_type_id = TI.id
    LEFT JOIN 
        cast_info CI ON FM.movie_id = CI.movie_id
    GROUP BY 
        FM.movie_id, FM.title, FM.production_year
)
SELECT 
    MD.movie_id,
    MD.title,
    MD.production_year,
    MD.cast_count,
    MD.movie_info,
    CASE 
        WHEN MD.cast_count > 5 THEN 'Large Cast'
        WHEN MD.cast_count BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast' 
    END AS cast_size,
    CASE 
        WHEN MD.movie_info = 'No Information' THEN NULL
        ELSE MD.movie_info
    END AS info_display
FROM 
    MovieDetails MD
WHERE 
    MD.production_year >= (SELECT MAX(production_year) - 10 FROM aka_title)
ORDER BY 
    MD.production_year DESC, MD.cast_count DESC
LIMIT 10;
