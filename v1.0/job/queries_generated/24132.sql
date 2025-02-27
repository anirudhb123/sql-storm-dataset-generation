WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS rn
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role AS role_name,
        COUNT(c.nr_order) AS role_count,
        DENSE_RANK() OVER (PARTITION BY c.movie_id ORDER BY COUNT(c.nr_order) DESC) AS role_rank
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, c.person_id, r.role
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        COUNT(DISTINCT co.country_code) AS unique_country_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
FamousMovies AS (
    SELECT 
        m.movie_id, 
        m.title,
        m.production_year,
        COALESCE(SUM(CASE WHEN k.keyword IN ('Oscar', 'Award', 'Best', 'Nominated') THEN 1 ELSE 0 END), 0) AS award_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id, m.title, m.production_year
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ar.role_name, 'Unknown Role') AS main_role,
    COALESCE(mcd.companies, 'No Companies') AS movie_companies,
    f.award_count,
    RANK() OVER (ORDER BY COALESCE(f.award_count, 0) DESC, rm.production_year DESC) AS movie_rank
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id AND ar.role_rank = 1
LEFT JOIN 
    MovieCompanyDetails mcd ON rm.movie_id = mcd.movie_id
LEFT JOIN 
    FamousMovies f ON rm.movie_id = f.movie_id
WHERE 
    rm.rn <= 10 
ORDER BY 
    movie_rank, rm.production_year DESC
FETCH FIRST 20 ROWS ONLY;
