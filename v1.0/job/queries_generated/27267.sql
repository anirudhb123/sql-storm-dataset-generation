WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        at.kind_id,
        ROW_NUMBER() OVER (PARTITION BY at.kind_id ORDER BY at.production_year DESC) AS title_rank
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON mk.movie_id = at.movie_id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        k.keyword ILIKE '%action%'
),
TitleCast AS (
    SELECT 
        rt.title,
        rt.production_year,
        p.name AS actor_name,
        c.nr_order,
        r.role AS role_name
    FROM 
        RankedTitles rt
    JOIN 
        complete_cast cc ON cc.movie_id = rt.id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name p ON p.person_id = ci.person_id
    JOIN 
        role_type r ON r.id = ci.role_id
    WHERE 
        rt.title_rank <= 5
),
CompanyInfo AS (
    SELECT 
        mt.title,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        movie_info mi ON mi.movie_id = mc.movie_id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
    JOIN 
        title mt ON mt.id = mc.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Distributor') 
        AND mi.info IS NOT NULL
)
SELECT 
    tc.title,
    tc.production_year,
    STRING_AGG(DISTINCT tc.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT ci.company_name, ', ') AS companies,
    COUNT(DISTINCT ci.company_name) AS company_count
FROM 
    TitleCast tc
LEFT JOIN 
    CompanyInfo ci ON ci.title = tc.title
GROUP BY 
    tc.title, 
    tc.production_year
ORDER BY 
    tc.production_year DESC, 
    tc.title;
