WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(c.person_id) OVER (PARTITION BY a.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN (
        SELECT 
            m.movie_id,
            STRING_AGG(k.keyword, ', ') AS keywords
        FROM 
            movie_keyword m
        JOIN 
            keyword k ON m.keyword_id = k.id
        GROUP BY 
            m.movie_id
    ) mk ON rm.id = mk.movie_id
),
FinalResults AS (
    SELECT 
        mw.title,
        mw.production_year,
        mw.keywords,
        mw.cast_count
    FROM 
        MoviesWithKeywords mw
    WHERE 
        mw.year_rank = 1 
        AND mw.cast_count > 5
)
SELECT 
    fr.title,
    fr.production_year,
    fr.keywords
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC;
