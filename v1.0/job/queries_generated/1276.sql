WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        COUNT(mk.keyword) FILTER (WHERE mk.keyword IS NOT NULL) OVER (PARTITION BY t.id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
), 
MovieCast AS (
    SELECT 
        cm.movie_id,
        COALESCE(ak.name, 'Unknown') AS actor_name,
        ct.kind AS role,
        ROW_NUMBER() OVER (PARTITION BY cm.movie_id ORDER BY cm.nr_order) AS actor_order
    FROM 
        cast_info cm
    JOIN 
        aka_name ak ON cm.person_id = ak.person_id
    LEFT JOIN 
        comp_cast_type ct ON cm.person_role_id = ct.id
), 
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.title,
    rm.production_year,
    mv.actor_name,
    mv.role,
    ci.company_name,
    ci.company_type,
    rm.keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mv ON rm.movie_id = mv.movie_id
FULL OUTER JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
WHERE 
    (rm.rn <= 5 OR mv.actor_order <= 5) 
    AND (ci.company_type IS NOT NULL OR ci.company_name IS NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.keyword_count DESC, 
    mv.actor_order ASC
LIMIT 100;
