WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id 
    GROUP BY 
        mt.title, mt.production_year
),
HighCastMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        COALESCE(
            (SELECT AVG(cast_count) FROM RankedMovies WHERE production_year = rm.production_year),
            0
        ) AS avg_cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > (SELECT AVG(cast_count) FROM RankedMovies WHERE production_year = rm.production_year)
),
RecentHighCastMovies AS (
    SELECT 
        hcm.movie_title,
        hcm.production_year,
        hcm.cast_count,
        RANK() OVER (ORDER BY hcm.production_year DESC) AS recent_rank
    FROM 
        HighCastMovies hcm
    WHERE 
        hcm.production_year > 2000
),
CompanyMovies AS (
    SELECT 
        mt.title AS movie_title,
        STRING_AGG(CN.name, ', ') AS company_names
    FROM 
        aka_title mt
    INNER JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    INNER JOIN 
        company_name CN ON mc.company_id = CN.id
    GROUP BY 
        mt.title
),
FinalResults AS (
    SELECT 
        rhm.movie_title,
        rhm.production_year,
        rhm.cast_count,
        cm.company_names
    FROM 
        RecentHighCastMovies rhm
    LEFT JOIN 
        CompanyMovies cm ON rhm.movie_title = cm.movie_title
    WHERE 
        cm.company_names IS NOT NULL OR rhm.cast_count > 5
)

SELECT 
    fr.movie_title,
    fr.production_year,
    fr.cast_count,
    COALESCE(fr.company_names, 'No Companies') AS company_names
FROM 
    FinalResults fr
WHERE 
    fr.production_year BETWEEN 2000 AND 2023
    AND EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id IN (SELECT movie_id FROM movie_keyword mk WHERE mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%'))
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Runtime')
        AND mi.info LIKE '%min%'
    )
ORDER BY 
    fr.cast_count DESC, 
    fr.production_year ASC;
