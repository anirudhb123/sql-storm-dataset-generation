WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyCount AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT company_id) AS total_companies
    FROM 
        movie_companies
    GROUP BY 
        movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cc.total_companies, 0) AS total_companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyCount cc ON rm.movie_id = cc.movie_id
    WHERE 
        rm.rn <= 10
)
SELECT 
    fm.title,
    fm.production_year,
    fm.total_companies,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, fm.total_companies
ORDER BY 
    fm.production_year DESC, fm.total_companies DESC
LIMIT 20;
