WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank,
        COUNT(ci.person_id) AS cast_count
    FROM 
        aka_title t
        LEFT JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS company_names,
        STRING_AGG(ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
        INNER JOIN company_name cn ON mc.company_id = cn.id
        INNER JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
FinalOutput AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        COALESCE(mo.info, 'No Info') AS additional_info,
        mc.company_names,
        mc.company_types
    FROM 
        TopMovies tm
        LEFT JOIN movie_info mo ON tm.movie_id = mo.movie_id AND mo.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
        LEFT JOIN MovieCompanies mc ON tm.movie_id = mc.movie_id
)
SELECT 
    title,
    production_year,
    cast_count,
    additional_info,
    company_names,
    company_types
FROM 
    FinalOutput
WHERE 
    cast_count > 1
    AND production_year IS NOT NULL
ORDER BY 
    production_year, cast_count DESC;

-- Test for possible ambiguity by checking for multiple company names of the same type
SELECT 
    movie_id,
    company_id,
    company_name,
    COUNT(DISTINCT company_type) AS unique_company_types
FROM (
    SELECT 
        mc.movie_id,
        mc.company_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
        JOIN company_type ct ON mc.company_type_id = ct.id
) AS Companies
GROUP BY 
    movie_id, company_id, company_name
HAVING 
    COUNT(DISTINCT company_type) > 1
ORDER BY 
    movie_id;
