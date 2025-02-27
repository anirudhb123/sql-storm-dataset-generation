WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredCompanies AS (
    SELECT 
        mc.movie_id, 
        c.name AS company_name, 
        ct.kind AS company_type,
        mc.note
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IN ('USA', 'UK') 
        AND mc.note IS DISTINCT FROM 'N/A'
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        r.role,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
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
FinalResults AS (
    SELECT 
        t.title AS title_name,
        t.production_year,
        COALESCE(ROW_NUMBER() OVER (ORDER BY t.production_year DESC), 0) AS reverse_rank,
        COALESCE(ac.actor_count, 0) AS total_actors,
        COALESCE(fc.company_name, 'Unknown') AS production_company,
        COALESCE(fc.company_type, 'N/A') AS type_of_company,
        COALESCE(mk.keywords, 'No keywords') AS movie_keywords
    FROM 
        RankedTitles t
    LEFT JOIN 
        ActorRoles ac ON t.title_id = ac.movie_id
    LEFT JOIN 
        FilteredCompanies fc ON t.title_id = fc.movie_id
    LEFT JOIN 
        MovieKeywords mk ON t.title_id = mk.movie_id
)
SELECT 
    title_name,
    production_year,
    reverse_rank,
    total_actors,
    production_company,
    type_of_company,
    movie_keywords
FROM 
    FinalResults
WHERE 
    (total_actors > 0 OR production_company IS NOT NULL)
    AND (production_year BETWEEN 2000 AND 2023)
ORDER BY 
    production_year DESC, 
    title_name;
