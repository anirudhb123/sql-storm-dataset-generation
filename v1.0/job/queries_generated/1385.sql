WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        c.kind_id, 
        t.production_year, 
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM 
        aka_title t
    JOIN 
        kind_type c ON t.kind_id = c.id
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id, 
        ak.name AS actor_name, 
        ci.nr_order, 
        rt.role 
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ak.name IS NOT NULL
),
MovieCompanies AS (
    SELECT 
        mc.movie_id, 
        GROUP_CONCAT(DISTINCT cn.name) AS companies, 
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id, 
    rm.title, 
    rm.production_year, 
    cd.actor_name, 
    cd.nr_order, 
    mc.companies, 
    mc.company_types
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE 
    (rm.year_rank <= 5 OR cd.nr_order IS NOT NULL) 
    AND (mc.companies IS NOT NULL OR mc.company_types IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
