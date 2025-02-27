WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) as rn
    FROM 
        title t
    JOIN 
        role_type r ON t.kind_id = r.id
),
CompanyInfo AS (
    SELECT 
        c.name AS company_name,
        ct.kind AS company_type,
        mc.movie_id
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
KeywordInfo AS (
    SELECT 
        m.title,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        title m ON mk.movie_id = m.id
),
CompleteCastInfo AS (
    SELECT 
        cc.movie_id,
        ak.name AS actor_name,
        ak.id AS actor_id,
        rc.role AS actor_role
    FROM 
        complete_cast cc
    JOIN 
        aka_name ak ON cc.subject_id = ak.id
    JOIN 
        cast_info ci ON cc.movie_id = ci.movie_id
    JOIN 
        role_type rc ON ci.role_id = rc.id
)
SELECT 
    rt.title,
    rt.production_year,
    ci.company_name,
    ci.company_type,
    ki.keyword,
    cci.actor_name,
    cci.actor_role
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyInfo ci ON rt.id = ci.movie_id
LEFT JOIN 
    KeywordInfo ki ON rt.title = ki.title
LEFT JOIN 
    CompleteCastInfo cci ON rt.id = cci.movie_id
WHERE 
    rt.rn = 1
ORDER BY 
    rt.production_year DESC, rt.title;
