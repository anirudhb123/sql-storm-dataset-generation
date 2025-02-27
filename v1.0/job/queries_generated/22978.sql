WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(ci.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_per_year,
        SUM(CASE WHEN ci.nr_order IS NULL THEN 1 ELSE 0 END) AS null_roles 
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.rank_per_year,
        COALESCE(rm.null_roles, 0) AS non_counted_roles 
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_per_year <= 5 AND
        rm.production_year >= 2000
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mci.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind LIKE '%Production%')
    GROUP BY 
        mc.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    cs.company_count,
    CASE 
        WHEN cs.company_count = 0 THEN 'No Companies Associated'
        ELSE cs.companies
    END AS associated_companies,
    RANK() OVER (ORDER BY fm.cast_count DESC) AS overall_rank
FROM 
    FilteredMovies fm
LEFT JOIN 
    CompanyStats cs ON fm.movie_id = cs.movie_id
ORDER BY 
    fm.production_year DESC, fm.cast_count DESC;
