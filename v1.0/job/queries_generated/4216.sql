WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_cast <= 5
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
        fm.movie_title,
        fm.production_year,
        fm.cast_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        MovieKeywords mk ON fm.production_year = (
            SELECT DISTINCT
                production_year 
            FROM 
                aka_title 
            WHERE 
                id IN (SELECT movie_id FROM movie_keyword WHERE movie_id IS NOT NULL)
        )
)
SELECT 
    fr.movie_title,
    fr.production_year,
    fr.cast_count,
    fr.keywords
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, fr.cast_count DESC;
