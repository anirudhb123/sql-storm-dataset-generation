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
        t.production_year IS NOT NULL
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
PopularMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.rn <= 10 AND rm.cast_count > 0
)
SELECT 
    pm.title,
    pm.production_year,
    pm.cast_count,
    pm.keywords,
    CASE 
        WHEN pm.cast_count > 5 THEN 'Ensemble Cast'
        WHEN pm.cast_count BETWEEN 3 AND 5 THEN 'Small Cast'
        ELSE 'Minimal Cast' 
    END AS cast_category
FROM 
    PopularMovies pm
ORDER BY 
    pm.production_year DESC, 
    pm.cast_count DESC
LIMIT 15;
