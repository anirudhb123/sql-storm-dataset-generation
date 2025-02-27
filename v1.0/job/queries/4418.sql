WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank
    FROM 
        aka_title AS mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies AS rm
    WHERE 
        rm.year_rank <= 5
),
CastInfo AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS main_roles
    FROM 
        cast_info AS ci
    GROUP BY 
        ci.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(ci.actor_count, 0) AS total_actors,
    COALESCE(ci.main_roles, 0) AS main_roles,
    COALESCE(mcomp.company_count, 0) AS production_companies,
    COALESCE(mcomp.companies, 'No Companies') AS company_names
FROM 
    TopMovies AS tm
LEFT JOIN 
    CastInfo AS ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    MovieCompanies AS mcomp ON tm.movie_id = mcomp.movie_id
WHERE 
    tm.production_year IS NOT NULL
ORDER BY 
    tm.production_year DESC;
