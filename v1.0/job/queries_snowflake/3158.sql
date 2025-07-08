
WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(cc.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(cc.id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
AwardedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        aka_title mt ON mc.movie_id = mt.id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind LIKE '%Award%')
    GROUP BY 
        mt.id, mt.title, mt.production_year
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(am.company_names, 'No Award Companies') AS award_companies
FROM 
    RankedMovies rm
LEFT JOIN 
    AwardedMovies am ON rm.title = am.title AND rm.production_year = am.production_year
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
