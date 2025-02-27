WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank
    FROM 
        aka_title m
),
CastInfoWithRoles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        ci.nr_order,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(cn.name SEPARATOR ', ') AS company_names,
        GROUP_CONCAT(ct.kind SEPARATOR ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        GROUP_CONCAT(k.keyword SEPARATOR ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(cwr.role, 'Unknown Role') AS leading_role,
    cd.company_names,
    cd.company_types,
    mk.keywords,
    CASE 
        WHEN rm.production_year < 2000 THEN 'Classic'
        WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CastInfoWithRoles cwr ON rm.movie_id = cwr.movie_id AND cwr.role_rank = 1
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank <= 5 OR 
    rm.production_year IS NULL
ORDER BY 
    CASE 
        WHEN rm.production_year IS NOT NULL THEN rm.production_year 
        ELSE 9999 END, 
    rm.title;
