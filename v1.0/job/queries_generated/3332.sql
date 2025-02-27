WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM aka_title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series'))
),
MovieDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(mk.keyword, 'N/A') AS keyword,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        CASE 
            WHEN (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = rm.id) > 0 
                THEN 'Has Complete Cast' 
            ELSE 'Missing Complete Cast' 
        END AS cast_status
    FROM RankedMovies rm
    LEFT JOIN movie_keyword mk ON rm.rn = mk.id
    LEFT JOIN movie_companies mc ON rm.rn = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    WHERE rm.cast_count > 5
),
FinalOutput AS (
    SELECT 
        title,
        production_year,
        keyword,
        company_name,
        cast_status,
        CASE 
            WHEN production_year IS NULL THEN 'Year Not Available' 
            ELSE 'Year Available' 
        END AS year_availability
    FROM MovieDetails
)
SELECT 
    title,
    production_year,
    keyword,
    company_name,
    cast_status,
    year_availability
FROM FinalOutput
WHERE year_availability = 'Year Available'
ORDER BY production_year DESC, title ASC
LIMIT 50;
