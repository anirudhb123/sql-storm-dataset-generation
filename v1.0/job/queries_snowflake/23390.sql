
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
PersonRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS role_count,
        LISTAGG(DISTINCT co.kind, ', ') WITHIN GROUP (ORDER BY co.kind) AS role_types
    FROM 
        cast_info ci
    LEFT JOIN 
        comp_cast_type co ON ci.person_role_id = co.id
    GROUP BY 
        ci.movie_id
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ' | ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        COUNT(DISTINCT mc.company_type_id) AS unique_company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.rn,
    rm.total_movies,
    mk.keywords,
    pr.role_count,
    pr.role_types,
    mcd.company_names,
    mcd.unique_company_types
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    PersonRoles pr ON rm.movie_id = pr.movie_id
LEFT JOIN 
    MovieCompanyDetails mcd ON rm.movie_id = mcd.movie_id
WHERE 
    (pr.role_count IS NULL OR pr.role_count >= 2) 
    AND (rm.production_year BETWEEN 2000 AND 2023) 
    AND (mcd.unique_company_types IS NULL OR mcd.unique_company_types > 1)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
