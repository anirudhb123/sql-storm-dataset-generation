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
CastRoles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(*) AS num_roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
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
)
SELECT 
    r.title,
    r.production_year,
    coalesce(c.role, 'Unknown') AS role,
    COALESCE(cd.company_name, 'No Company') AS company_name,
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    r.title_rank,
    CASE 
        WHEN c.num_roles > 1 THEN 'Multiple Roles' 
        ELSE 'Single Role' 
    END AS role_type
FROM 
    RankedMovies r
LEFT JOIN 
    CastRoles c ON r.movie_id = c.movie_id
LEFT JOIN 
    CompanyDetails cd ON r.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords k ON r.movie_id = k.movie_id
WHERE 
    r.title_rank <= 5
ORDER BY 
    r.production_year DESC, 
    r.title;
