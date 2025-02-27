WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
PersonRoles AS (
    SELECT 
        c.person_id,
        c.movie_id,
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id, c.movie_id, r.role
),
ExternalCompanies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),

-- Get movies produced by multiple companies
MoviesWithMultipleCompanies AS (
    SELECT 
        movie_id,
        ARRAY_AGG(DISTINCT company_name) AS companies
    FROM 
        ExternalCompanies
    GROUP BY 
        movie_id
    HAVING 
        COUNT(*) > 1
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.title_rank,
    COALESCE(pr.role_count, 0) AS total_roles,
    mwc.companies,
    rm.keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    PersonRoles pr ON rm.movie_id = pr.movie_id
LEFT JOIN 
    MoviesWithMultipleCompanies mwc ON rm.movie_id = mwc.movie_id
WHERE 
    rm.title_rank <= 5    -- Top 5 titles per production year
    AND (rm.keyword_count > 2 OR mwc.companies IS NOT NULL)  -- Have enough keywords or produced by multiple companies
ORDER BY 
    rm.production_year DESC, 
    rm.title_rank;

