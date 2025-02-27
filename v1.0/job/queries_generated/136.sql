WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%action%'
),
CompanyInfo AS (
    SELECT 
        c.name AS company_name,
        mt.kind AS company_type,
        mc.movie_id
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type mt ON mc.company_type_id = mt.id
    WHERE 
        mt.kind IN ('Distributor', 'Production')
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT co.k) AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type co ON ci.role_id = co.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(cr.actor_count, 0) AS total_actors,
    ci.company_name,
    ci.company_type,
    CASE 
        WHEN rm.rn <= 10 THEN 'Top Releases'
        ELSE 'Other Releases'
    END AS release_category,
    STRING_AGG(DISTINCT cr.roles::text, ', ') AS actor_roles
FROM 
    RankedMovies rm
LEFT JOIN 
    CastRoles cr ON rm.title = cr.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.production_year = ci.movie_id
WHERE 
    rm.production_year >= 2000
GROUP BY 
    rm.title, rm.production_year, cr.actor_count, ci.company_name, ci.company_type, rm.rn
ORDER BY 
    rm.production_year DESC, total_actors DESC, rm.title;
