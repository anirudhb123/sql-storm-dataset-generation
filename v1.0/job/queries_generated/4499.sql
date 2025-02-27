WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        ct.kind AS company_type
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT r.role ORDER BY r.role) AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        c.country_code
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
)
SELECT 
    md.title,
    md.production_year,
    md.keyword,
    cr.roles,
    COALESCE(cd.company_name, 'No Company') AS company_name,
    COALESCE(cd.country_code, 'Unknown') AS country_code,
    rt.rank_year
FROM 
    MovieDetails md
LEFT JOIN 
    CastRoles cr ON md.movie_id = cr.movie_id
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    RankedTitles rt ON md.production_year = rt.production_year
WHERE 
    (md.production_year BETWEEN 2000 AND 2020)
    AND (md.keyword IS NOT NULL OR md.keyword = 'No Keywords')
ORDER BY 
    md.production_year DESC, md.title
OFFSET 10 LIMIT 20;
