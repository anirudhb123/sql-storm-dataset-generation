WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')
),
FilteredCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS row_num
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
),
CombinedData AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        c.company_name,
        c.company_type,
        CASE 
            WHEN c.company_type IS NOT NULL THEN COUNT(DISTINCT c.company_name) OVER (PARTITION BY m.movie_id)
            ELSE 0 
        END AS company_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        FilteredCompanies c ON m.movie_id = c.movie_id
)
SELECT 
    cd.movie_id,
    cd.title,
    cd.production_year,
    cd.company_name,
    cd.company_type,
    cd.company_count
FROM 
    CombinedData cd
WHERE 
    cd.rank_within_year <= 5
    AND (cd.company_count IS NULL OR cd.company_count > 1)
ORDER BY 
    cd.production_year DESC, 
    cd.movie_id ASC
LIMIT 100
OFFSET 0;

-- Additional check for movies released after 2000 with NULL company info
UNION ALL
SELECT 
    cd.movie_id,
    cd.title,
    cd.production_year,
    cd.company_name,
    cd.company_type,
    cd.company_count
FROM 
    CombinedData cd
WHERE 
    cd.production_year > 2000 AND cd.company_name IS NULL
ORDER BY 
    cd.production_year DESC
LIMIT 50;

-- String concatenation of titles and company names for visualization
WITH FinalOutput AS (
    SELECT 
        cd.movie_id,
        STRING_AGG(CONCAT(cd.title, ' (', COALESCE(cd.company_name, 'N/A'), ')'), '; ') AS movie_info
    FROM 
        CombinedData cd
    GROUP BY 
        cd.movie_id
)
SELECT 
    movie_info
FROM 
    FinalOutput
WHERE 
    LENGTH(movie_info) > 50
ORDER BY 
    movie_info DESC;

This query uses a variety of SQL constructs, including CTEs, window functions, joins, and complicated predicates, to extract a set of benchmark criteria pertaining to movies, companies, and roles based on specific conditions and logic. It includes use of NULL handling, aggregate functions, string manipulation, and ordering to create a rich result set while ensuring performance is maintained through filtering and limiting results.
