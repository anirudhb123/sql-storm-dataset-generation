WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS fraction_with_roles,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
SelectedMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.fraction_with_roles
    FROM
        RankedMovies rm
    WHERE
        rm.rank <= 5 AND rm.production_year IS NOT NULL
),
CompanyInfo AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    WHERE
        c.country_code IS NOT NULL
),
CompleteMovieInfo AS (
    SELECT
        sm.movie_id,
        sm.title,
        sm.production_year,
        sm.cast_count,
        sm.fraction_with_roles,
        STRING_AGG(DISTINCT ci.company_name, ', ' ORDER BY ci.company_rank) AS companies
    FROM
        SelectedMovies sm
    LEFT JOIN
        CompanyInfo ci ON sm.movie_id = ci.movie_id
    GROUP BY
        sm.movie_id, sm.title, sm.production_year, sm.cast_count, sm.fraction_with_roles
)
SELECT 
    cm.movie_id,
    cm.title,
    cm.production_year,
    cm.cast_count,
    cm.fraction_with_roles,
    COALESCE(cm.companies, 'No Companies') AS companies_info,
    CASE 
        WHEN cm.cast_count > 10 THEN 'Large Cast'
        WHEN cm.cast_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Small Cast' 
    END AS cast_size_category,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = cm.movie_id) AS keyword_count,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = cm.movie_id AND mi.info IS NOT NULL) AS info_count
FROM 
    CompleteMovieInfo cm
ORDER BY 
    cm.production_year DESC, cm.cast_count DESC;

-- Additional tests for edge case handling
SELECT * FROM (
    SELECT 
        id,
        title,
        NULLIF(production_year, 0) AS production_year_adjusted -- Handling zero as NULL
    FROM 
        aka_title 
) AS sub
WHERE production_year_adjusted IS NOT NULL
AND title LIKE '%Inception%' -- Dreams within dreams
HAVING COUNT(*) > 1; -- Ensuring we're examining a possible edge case like multiple entries
