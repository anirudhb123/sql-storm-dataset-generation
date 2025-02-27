WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        title t
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(CASE WHEN r.role = 'Lead' THEN 1 ELSE 0 END) AS has_lead_role
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
KeywordInfo AS (
    SELECT 
        mk.movie_id,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    cd.total_cast,
    cd.has_lead_role,
    ci.companies,
    ci.company_types,
    ki.keywords
FROM 
    RankedTitles rt
JOIN 
    CastDetails cd ON rt.title_id = cd.movie_id
JOIN 
    CompanyInfo ci ON rt.title_id = ci.movie_id
JOIN 
    KeywordInfo ki ON rt.title_id = ki.movie_id
WHERE 
    rt.rank_per_year <= 5 -- Top 5 titles per production year
ORDER BY 
    rt.production_year ASC, rt.title ASC;
