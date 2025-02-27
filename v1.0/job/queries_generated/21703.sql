WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),
CastInfoStats AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        COUNT(DISTINCT ci.role_id) AS unique_roles,
        MAX(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note
    FROM cast_info ci
    GROUP BY ci.movie_id
),
MovieCompaniesInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.unique_roles, 0) AS unique_roles,
    CASE
        WHEN cs.has_note = 1 THEN 'Yes'
        ELSE 'No'
    END AS has_note,
    COALESCE(mci.company_names, 'None') AS company_names,
    COALESCE(mci.company_types, 'None') AS company_types
FROM RankedMovies rm
LEFT JOIN CastInfoStats cs ON rm.movie_id = cs.movie_id
LEFT JOIN MovieCompaniesInfo mci ON rm.movie_id = mci.movie_id
WHERE rm.year_rank <= 5
ORDER BY rm.production_year DESC, rm.title
LIMIT 50;

-- This query retrieves the top 5 movies per year from the ranked movie list, 
-- including statistics about cast and associated companies.
-- It uses Common Table Expressions (CTEs), outer joins, and handles NULL logic
-- by providing default values for missing data, while the ranking is done 
-- based on production year descending.
