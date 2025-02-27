WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
MovieInfoText AS (
    SELECT 
        mi.movie_id, 
        STRING_AGG(mi.info, ', ' ORDER BY mi.info_type_id) AS full_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)

SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    COALESCE(cd.company_name, 'Unknown') AS company_name,
    COALESCE(cd.company_type, 'Unknown') AS company_type,
    COALESCE(cd.total_companies, 0) AS total_companies,
    mit.full_info
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.title_id = ac.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.title_id = cd.movie_id
LEFT JOIN 
    MovieInfoText mit ON rm.title_id = mit.movie_id
WHERE 
    (rm.production_year BETWEEN 2000 AND 2023 OR rm.production_year IS NULL)
    AND (cd.total_companies > 0 OR cd.total_companies IS NULL)
ORDER BY 
    rm.production_year DESC, 
    actor_count DESC,
    rm.title;

-- Additional performance expressions with a Bizarre Case
WITH UnexpectedCounts AS (
    SELECT 
        c.movie_id,
        SUM(CASE WHEN c.note LIKE '%Cameo%' THEN 1 ELSE 0 END) AS cameo_count,
        MAX(CASE WHEN c.nr_order IS NULL THEN 1 ELSE 0 END) AS has_null_order_flag
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
)
SELECT 
    rm.title,
    COALESCE(uc.cameo_count, 0) AS cameo_count,
    COALESCE(uc.has_null_order_flag, 0) AS has_null_order
FROM 
    RankedMovies rm
LEFT JOIN 
    UnexpectedCounts uc ON rm.title_id = uc.movie_id
WHERE 
    (uc.cameo_count = 0 OR uc.has_null_order_flag = 1)
ORDER BY 
    rm.production_year DESC, 
    cameo_count DESC;

