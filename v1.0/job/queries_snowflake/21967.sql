
WITH RecursiveMovie AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000
),
CTE_ExternalCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS rn
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL AND 
        UPPER(c.country_code) NOT LIKE '%USA%'
),
CTE_CompleteCast AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS actor_names
    FROM 
        complete_cast cc
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name cn ON ci.person_id = cn.person_id
    GROUP BY 
        cc.movie_id
)
SELECT 
    m.title_id,
    m.title,
    m.production_year,
    LISTAGG(DISTINCT ec.company_name, ', ') WITHIN GROUP (ORDER BY ec.company_name) AS external_companies,
    ec.company_type AS company_type,
    cc.total_actors,
    cc.actor_names
FROM 
    RecursiveMovie m
LEFT JOIN 
    CTE_ExternalCompanies ec ON m.title_id = ec.movie_id
LEFT JOIN 
    CTE_CompleteCast cc ON m.title_id = cc.movie_id
WHERE 
    m.rn < 5  
GROUP BY 
    m.title_id, m.title, m.production_year, ec.company_type, cc.total_actors, cc.actor_names
HAVING 
    COUNT(DISTINCT ec.company_name) > 1 
ORDER BY 
    m.production_year DESC, 
    m.title;
