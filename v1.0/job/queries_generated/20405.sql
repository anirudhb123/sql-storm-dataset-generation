WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mc.company_id,
        c.name AS company_name,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mc.company_id ORDER BY mt.production_year DESC) AS rn
    FROM 
        aka_title mt
        JOIN movie_companies mc ON mt.id = mc.movie_id
        LEFT JOIN company_name c ON mc.company_id = c.id
    WHERE 
        mt.production_year IS NOT NULL
),

TopCompanies AS (
    SELECT 
        cm.company_id, 
        COUNT(*) AS movie_count,
        STRING_AGG(DISTINCT rv.name ORDER BY rv.name DESC) AS cast_names
    FROM 
        RankedMovies rv
        JOIN movie_companies mc ON rv.company_id = mc.company_id
    GROUP BY 
        cm.company_id
    HAVING 
        COUNT(*) > 5
)

SELECT 
    tc.movie_count,
    tc.company_id,
    tc.cast_names,
    'Company has produced ' || tc.movie_count || ' movies featuring ' || COALESCE(tc.cast_names, 'No cast info') || '!' AS message
FROM 
    TopCompanies tc
WHERE 
    NOT EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id IN (SELECT DISTINCT movie_id FROM movie_companies WHERE company_id = tc.company_id) AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'BoxOffice'))
ORDER BY 
    tc.movie_count DESC
LIMIT 10;

