WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(ci.person_id) AS cast_count
    FROM
        aka_title t
    LEFT JOIN
        cast_info ci ON t.movie_id = ci.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.*,
        CASE WHEN rm.cast_count > 5 THEN 'Large Ensemble'
             WHEN rm.cast_count BETWEEN 3 AND 5 THEN 'Medium Ensemble'
             ELSE 'Small Ensemble' END AS ensemble_size
    FROM
        RankedMovies rm
    WHERE
        rm.title_rank <= 5
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
FinalResults AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.ensemble_size,
        COALESCE(mk.keywords, '[No Keywords]') AS movie_keywords,
        RANK() OVER (ORDER BY fm.production_year DESC) AS year_rank
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        MovieKeywords mk ON fm.movie_id = mk.movie_id
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.ensemble_size,
    fr.movie_keywords,
    fr.year_rank,
    CASE 
        WHEN fr.production_year < 2000 THEN 'Classic' 
        WHEN fr.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    FinalResults fr
WHERE 
    fr.ensemble_size != 'Small Ensemble'
    AND fr.year_rank <= 10
ORDER BY 
    fr.production_year DESC,
    fr.title;