WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS title_kind,
        ROW_NUMBER() OVER (PARTITION BY kt.kind ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    WHERE 
        t.production_year IS NOT NULL
),
ActorStats AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies_played
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    GROUP BY 
        a.person_id, a.name
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies_involved,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
TitleCompanyInfo AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.title_kind,
        cs.companies_involved,
        cs.company_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CompanyStats cs ON rt.title_id = cs.movie_id
)
SELECT 
    ats.person_id,
    ats.name AS actor_name,
    tci.title,
    tci.production_year,
    tci.title_kind,
    tci.companies_involved,
    tci.company_count,
    ats.movie_count,
    ats.movies_played
FROM 
    ActorStats ats
JOIN 
    TitleCompanyInfo tci ON ats.movie_count > 0
ORDER BY 
    ats.movie_count DESC, tci.production_year DESC
LIMIT 100;
