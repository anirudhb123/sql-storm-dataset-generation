WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

CompanyData AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY ct.kind) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL AND 
        ct.kind IS NOT NULL
),

CastSummary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT ci.role_id) FILTER (WHERE ci.role_id IS NOT NULL) AS lead_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
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

FinalResults AS (
    SELECT 
        rm.title AS movie_title,
        rm.production_year,
        cd.company_name,
        cd.company_type,
        cs.total_cast,
        cs.lead_roles,
        mk.keywords,
        CASE WHEN cs.total_cast > 10 THEN 'Ensemble Cast' ELSE 'Limited Cast' END AS cast_size
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyData cd ON rm.movie_id = cd.movie_id AND cd.company_rank = 1
    LEFT JOIN 
        CastSummary cs ON rm.movie_id = cs.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
)

SELECT 
    *,
    CASE 
        WHEN production_year < 2000 THEN 'Classic'
        WHEN production_year BETWEEN 2000 AND 2010 THEN 'Modern Era'
        ELSE 'Contemporary'
    END AS era,
    COALESCE(keywords, 'No Keywords') AS keyword_summary
FROM 
    FinalResults
ORDER BY 
    production_year DESC, movie_title ASC
LIMIT 50 OFFSET 0;

