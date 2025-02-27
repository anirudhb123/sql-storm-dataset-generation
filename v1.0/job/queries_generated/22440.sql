WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        ci.movie_id,
        COALESCE(r.role, 'Unknown Role') AS role_name,
        ci.nr_order
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        MAX(CASE WHEN ct.kind = 'Production' THEN c.name END) AS production_company
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        t.title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        a.role_name,
        mk.keywords,
        mc.companies,
        mc.production_company
    FROM 
        RankedTitles t
    LEFT JOIN 
        ActorDetails a ON t.title_id = a.movie_id
    LEFT JOIN 
        MovieKeywords mk ON t.title_id = mk.movie_id
    LEFT JOIN 
        MovieCompanies mc ON t.title_id = mc.movie_id
)
SELECT 
    fr.title_id,
    fr.title,
    fr.production_year,
    fr.actor_name,
    fr.role_name,
    fr.keywords,
    fr.companies,
    fr.production_company
FROM 
    FinalResults fr
WHERE 
    fr.title_rank = 1 OR (fr.production_year IS NULL AND fr.actor_name IS NOT NULL)
ORDER BY 
    fr.production_year DESC, fr.title ASC;
