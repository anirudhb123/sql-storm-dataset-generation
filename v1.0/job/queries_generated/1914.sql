WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredCast AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        a.name AS actor_name,
        rt.role AS role_name,
        COALESCE(c.nr_order, 0) AS order_in_cast
    FROM 
        cast_info c
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN role_type rt ON c.role_id = rt.id
    WHERE 
        a.surname_pcode IS NOT NULL
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    fc.actor_name,
    fc.role_name,
    mc.company_count,
    mc.companies,
    RANK() OVER (PARTITION BY rm.production_year ORDER BY mc.company_count DESC) AS company_rank
FROM 
    RankedMovies rm
LEFT JOIN FilteredCast fc ON rm.movie_id = fc.movie_id
LEFT JOIN MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC,
    mc.company_count DESC,
    fc.order_in_cast;
