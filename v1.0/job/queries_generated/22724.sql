WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(DISTINCT k.keyword) OVER (PARTITION BY t.id) AS keyword_count,
        COALESCE(mci.name, 'Unknown Company') AS company_name
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name mci ON mc.company_id = mci.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
CompanyRoles AS (
    SELECT 
        ci.movie_id,
        ct.kind AS company_type,
        COUNT(DISTINCT ci.person_role_id) AS unique_roles
    FROM 
        cast_info ci
    JOIN 
        movie_companies mc ON ci.movie_id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        ci.movie_id, ct.kind
),
CombinedResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.title_rank,
        rm.keyword_count,
        cr.company_type,
        cr.unique_roles
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyRoles cr ON rm.movie_id = cr.movie_id
)
SELECT 
    cb.title,
    cb.production_year,
    cb.title_rank,
    COALESCE(cb.company_type, 'No Company Type') AS company_type,
    CASE WHEN cb.unique_roles IS NULL THEN 'No Roles' 
         WHEN cb.unique_roles > 10 THEN 'Many Roles' 
         ELSE 'Few Roles' END AS role_category,
    STRING_AGG(DISTINCT ak.name, ', ') AS akas
FROM 
    CombinedResults cb
LEFT JOIN 
    aka_name ak ON cb.movie_id = ak.person_id
WHERE 
    cb.production_year BETWEEN 2000 AND 2023
GROUP BY 
    cb.movie_id, cb.title, cb.production_year, cb.title_rank, cb.company_type, cb.unique_roles
HAVING 
    COUNT(ak.id) > 1 -- only movies with multiple aka names
ORDER BY 
    cb.production_year DESC, cb.title_rank;
