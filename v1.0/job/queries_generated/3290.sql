WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),

CastRoles AS (
    SELECT 
        c.movie_id,
        c.role_id,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id, c.role_id
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
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code IS NOT NULL
),

AggregateMovieInfo AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        COUNT(DISTINCT cr.role_id) AS distinct_roles,
        STRING_AGG(DISTINCT ci.company_name, ', ') AS companies
    FROM 
        MovieDetails md
    LEFT JOIN 
        CastRoles cr ON md.movie_id = cr.movie_id
    LEFT JOIN 
        CompanyInfo ci ON md.movie_id = ci.movie_id
    GROUP BY 
        md.movie_id, md.movie_title, md.production_year
)

SELECT 
    am.movie_id,
    am.movie_title,
    am.production_year,
    am.distinct_roles,
    am.companies,
    CASE 
        WHEN am.distinct_roles > 5 THEN 'Multiple Roles'
        ELSE 'Few Roles'
    END AS role_description,
    (SELECT COUNT(*) FROM cast_info WHERE movie_id = am.movie_id) AS total_cast
FROM 
    AggregateMovieInfo am
WHERE 
    am.production_year > 2000
ORDER BY 
    am.production_year DESC, am.movie_title;
