
WITH RankedMovies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_in_year
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mt.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
MoviesWithHighBudget AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COALESCE(mvi.info, 'N/A') AS budget_info
    FROM 
        aka_title title
    LEFT JOIN 
        movie_info mvi ON title.id = mvi.movie_id AND mvi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
    WHERE 
        (title.production_year > 2000 AND mvi.info IS NOT NULL)
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mc.company_names, 'Unknown Companies') AS company_names,
    COALESCE(mc.company_types, 'Unknown Types') AS company_types,
    CASE 
        WHEN rm.total_cast = 0 THEN 'No Cast'
        WHEN rm.rank_in_year <= 5 THEN 'Top 5 Cast'
        ELSE 'Standard'
    END AS cast_category,
    CASE 
        WHEN mhb.budget_info IS NULL THEN 'Low Budget'
        ELSE mhb.budget_info
    END AS financial_status
FROM
    RankedMovies rm
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    MoviesWithHighBudget mhb ON rm.movie_id = mhb.movie_id
WHERE 
    (rm.rank_in_year <= 10 OR mhb.budget_info IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast DESC;
