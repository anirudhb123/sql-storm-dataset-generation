WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND t.production_year IS NOT NULL
),
MovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mi.info, 'No info available') AS movie_info,
        mcc.company_name,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name mcc ON mc.company_id = mcc.id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, mi.info, mcc.company_name
),
FinalResults AS (
    SELECT 
        *,
        CASE 
            WHEN cast_count >= 5 THEN 'Ensemble Cast'
            WHEN cast_count BETWEEN 2 AND 4 THEN 'Small Cast'
            ELSE 'Solo Performance'
        END AS cast_type,
        CASE 
            WHEN production_year > 2000 THEN 'Modern Era'
            ELSE 'Classic Era'
        END AS movie_era
    FROM 
        MovieInfo
)
SELECT 
    movie_id, 
    title, 
    production_year, 
    movie_info,
    company_name,
    keyword_count,
    cast_type,
    movie_era
FROM 
    FinalResults
WHERE 
    (production_year > 2010 OR cast_count >= 3)
ORDER BY 
    production_year DESC, 
    title ASC;
