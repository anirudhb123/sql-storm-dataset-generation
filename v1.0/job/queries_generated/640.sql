WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
HighCastMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieCompanyCount AS (
    SELECT 
        at.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    GROUP BY 
        at.id
)
SELECT 
    hcm.title,
    hcm.production_year,
    hcm.cast_count,
    COALESCE(mcc.company_count, 0) AS company_count,
    (SELECT 
         STRING_AGG(DISTINCT ak.name, ', ') 
     FROM 
         aka_name ak 
     WHERE 
         ak.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = hcm.movie_id)) AS cast_names
FROM 
    HighCastMovies hcm
LEFT JOIN 
    MovieCompanyCount mcc ON hcm.movie_id = mcc.movie_id
WHERE 
    hcm.production_year >= 2000
ORDER BY 
    hcm.production_year DESC, hcm.cast_count DESC;
