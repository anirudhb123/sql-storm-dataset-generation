WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
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
    rm.title,
    rm.production_year,
    mk.keywords,
    ac.role,
    ac.role_count,
    mci.companies,
    mci.company_types
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    ActorRoles ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    MovieCompanyInfo mci ON rm.movie_id = mci.movie_id
WHERE 
    rm.year_rank <= 5 -- Only the top 5 movies per year
    AND (mk.keywords IS NOT NULL OR ac.role_count > 0)
ORDER BY 
    rm.production_year DESC, rm.title ASC;

-- The above query demonstrates various SQL features:
-- 1. CTEs to organize complicated aggregations and analyses.
-- 2. The use of STRING_AGG to concatenate actor roles and keywords.
-- 3. Row-level ranking per year for movies produced.
-- 4. The filtering conditions that require non-null values for columns 
--    from multiple CTEs to ensure integrity.
-- 5. A complicated WHERE clause that combines conditions on NULL values.
