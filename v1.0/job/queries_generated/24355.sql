WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        COALESCE(c.name, 'Unknown') AS company_name,
        COUNT(DISTINCT c.id) OVER (PARTITION BY at.id) AS total_companies,
        RANK() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank_per_year
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
),

TopRankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        company_name,
        total_companies
    FROM 
        RankedMovies
    WHERE 
        rank_per_year <= 5
),

MovieRoles AS (
    SELECT 
        at.title,
        COUNT(DISTINCT ci.id) AS role_count,
        COUNT(DISTINCT CASE WHEN rt.role LIKE '%Director%' THEN ci.id END) AS director_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        at.title
)

SELECT 
    tr.movie_title,
    tr.production_year,
    tr.company_name,
    tr.total_companies,
    COALESCE(mr.role_count, 0) AS total_roles,
    CASE 
        WHEN tr.total_companies > 1 AND mr.director_count = 0 THEN 'No Directors Found'
        WHEN tr.total_companies IS NULL THEN 'No Companies Attached'
        ELSE 'Valid'
    END AS validation_status,
    CONCAT('Movie: ', tr.movie_title, ' (', tr.production_year, ') has ', 
           tr.total_companies, ' companies and ', COALESCE(mr.role_count, 0), ' roles. ', 
           validation_status) AS summary
FROM 
    TopRankedMovies tr
LEFT JOIN 
    MovieRoles mr ON tr.movie_title = mr.title
WHERE 
    tr.production_year IS NOT NULL
ORDER BY 
    tr.production_year DESC, tr.total_companies DESC;
