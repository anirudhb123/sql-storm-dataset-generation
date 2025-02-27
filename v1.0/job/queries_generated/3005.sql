WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY at.id) AS cast_count
    FROM 
        aka_title at
    JOIN 
        complete_cast cc ON at.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        at.production_year IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        r.title,
        r.production_year,
        k.keyword,
        r.cast_count
    FROM 
        RankedMovies r
    LEFT JOIN 
        movie_keyword mk ON r.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        r.rank_year <= 5
),
FinalResults AS (
    SELECT 
        mwk.title,
        mwk.production_year,
        COALESCE(mwk.keyword, 'No Keyword') AS keyword,
        mwk.cast_count,
        CASE 
            WHEN mwk.cast_count > 10 THEN 'Ensemble Cast'
            WHEN mwk.cast_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
            ELSE 'Small Cast' 
        END AS cast_size
    FROM 
        MoviesWithKeywords mwk
)
SELECT 
    f.title,
    f.production_year,
    f.keyword,
    f.cast_count,
    f.cast_size
FROM 
    FinalResults f
ORDER BY 
    f.production_year DESC, 
    f.cast_count DESC;
