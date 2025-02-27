WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        RANK() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
        AND t.title ILIKE '%love%'  -- Filtering titles containing "love"
),
ActorsWithMultipleRoles AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.role_id) > 1  -- Selecting actors with multiple distinct roles
),
CompanyProductionYears AS (
    SELECT 
        mc.movie_id,
        mc.company_id,
        mc.company_type_id,
        MIN(t.production_year) AS first_production_year
    FROM 
        movie_companies mc
    JOIN 
        aka_title t ON mc.movie_id = t.movie_id
    GROUP BY 
        mc.movie_id, mc.company_id, mc.company_type_id
)
SELECT 
    rt.title,
    rt.production_year,
    rt.keyword,
    a.name AS actor_name,
    cp.first_production_year,
    ac.role_count
FROM 
    RankedTitles rt
JOIN 
    complete_cast cc ON rt.title_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    CompanyProductionYears cp ON rt.title_id = cp.movie_id
JOIN 
    ActorsWithMultipleRoles ac ON ci.person_id = ac.person_id
WHERE 
    rt.rank <= 5  -- Limiting to top 5 longest titles per production year
ORDER BY 
    rt.production_year, rt.title;
