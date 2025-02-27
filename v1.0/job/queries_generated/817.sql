WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TitleKeywords AS (
    SELECT 
        t.id AS title_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    INNER JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompanyData AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
PersonInfo AS (
    SELECT 
        pi.person_id,
        STRING_AGG(DISTINCT pi.info, '; ') AS person_details
    FROM 
        person_info pi
    GROUP BY 
        pi.person_id
)
SELECT 
    rt.title,
    rt.production_year,
    rt.actor_count,
    tk.keyword,
    cd.companies,
    pi.person_details
FROM 
    RankedTitles rt
LEFT JOIN 
    TitleKeywords tk ON rt.id = tk.title_id AND tk.keyword_rank <= 3
LEFT JOIN 
    CompanyData cd ON rt.id = cd.movie_id
LEFT JOIN 
    (SELECT
         DISTINCT c.person_id,
         STRING_AGG(DISTINCT n.name, ', ') AS person_names
     FROM 
         cast_info c
     INNER JOIN 
         aka_name n ON c.person_id = n.person_id
     GROUP BY 
         c.person_id) pn ON rt.actor_count > 2 AND pn.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = rt.id)
LEFT JOIN 
    PersonInfo pi ON pi.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = rt.id)
WHERE 
    rt.rank <= 5
ORDER BY 
    rt.production_year DESC, rt.actor_count DESC;
