WITH RecursiveMovieTitle AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
    UNION ALL
    SELECT 
        mt.movie_id,
        mt.movie_title || ' (Reboot)' AS movie_title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.movie_title) AS title_rn
    FROM 
        RecursiveMovieTitle mt
    WHERE 
        mt.title_rn < 5 -- Arbitrary limit for recursive titles, simulating multiple reboots
),
CompanyInfo AS (
    SELECT 
        c.id AS company_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        company_name c
    JOIN 
        company_type ct ON c.id = ct.id
)
SELECT 
    mk.movie_id,
    rt.movie_title,
    rt.production_year,
    ci.company_name,
    ci.company_type,
    COUNT(DISTINCT ca.person_id) AS total_cast,
    SUM(CASE 
            WHEN ca.person_role_id IS NULL THEN 1
            ELSE 0 
        END) AS null_role_count,
    ARRAY_AGG(DISTINCT k.keyword) FILTER (WHERE k.keyword IS NOT NULL) AS keywords,
    MAX(CASE 
            WHEN ci.country_code IS NULL THEN 'Unknown' 
            ELSE ci.country_code 
        END) AS effective_country_code
FROM 
    RecursiveMovieTitle rt
LEFT JOIN 
    movie_keyword mk ON rt.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON rt.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ca ON ca.movie_id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = rt.movie_id
LEFT JOIN 
    CompanyInfo ci ON mc.company_id = ci.company_id
WHERE 
    rt.title_rn <= 3 -- Limit to three titles per year
GROUP BY 
    mk.movie_id, rt.movie_title, rt.production_year, ci.company_name, ci.company_type
HAVING 
    COUNT(DISTINCT ca.person_id) > 0 AND 
    COUNT(DISTINCT mk.keyword_id) > 1
ORDER BY 
    rt.production_year DESC, 
    effective_country_code NULLS LAST
LIMIT 100;
