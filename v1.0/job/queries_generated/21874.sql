WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rank,
        COALESCE(SUBSTRING(mt.title FROM '[^ ]+$'), 'Unknown') AS last_word,
        CASE 
            WHEN mt.production_year IS NOT NULL THEN 'Released'
            ELSE 'Unreleased'
        END AS release_status
    FROM aka_title mt
    WHERE mt.production_year >= 2000
), MovieActors AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MAX(a.name) AS leading_actor,
        MAX(CASE WHEN a.name IS NOT NULL THEN a.name END) AS official_lead,
        COUNT(DISTINCT COALESCE(a.gender, 'Unknown')) AS distinct_genders
    FROM cast_info c
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
), MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        SUM(CASE 
            WHEN ct.kind = 'Production' THEN 1 
            ELSE 0 
            END) AS production_companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
), CompleteView AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ma.actor_count,
        ma.leading_actor,
        ma.distinct_genders,
        mc.company_names,
        mc.production_companies,
        rm.last_word,
        rm.release_status
    FROM RankedMovies rm
    LEFT JOIN MovieActors ma ON rm.movie_id = ma.movie_id
    LEFT JOIN MovieCompanies mc ON rm.movie_id = mc.movie_id
)

SELECT 
    cv.title,
    cv.production_year,
    cv.actor_count,
    cv.company_names,
    CASE 
        WHEN cv.production_year < 2010 THEN 'Old'
        WHEN cv.production_year BETWEEN 2010 AND 2019 THEN 'Recent'
        ELSE 'New'
    END AS age_category,
    cv.release_status,
    MakeFakeData(cv.production_year) AS fake_data -- Assuming MakeFakeData is a user-defined function returning a string based on the year
FROM CompleteView cv
WHERE (cv.actor_count > 5 OR cv.release_status = 'Unreleased')
  AND (cv.production_year IS NOT NULL AND cv.production_year > 2000)
ORDER BY 
    CASE cv.production_year 
        WHEN 2012 THEN 1 
        WHEN 2015 THEN 2 
        ELSE 3 
    END,
    cv.title ASC NULLS LAST
LIMIT 50;

-- Assume MakeFakeData is a defined function elsewhere that takes an integer and returns some string.
