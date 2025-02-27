WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorTitles AS (
    SELECT 
        a.person_id,
        at.title,
        a.name,
        ot.role,
        COALESCE(a.name_pcode_nf, 'UNKNOWN') AS pcode_nf
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    LEFT JOIN 
        role_type ot ON ci.role_id = ot.id
    WHERE 
        a.name IS NOT NULL
),
MovieCompaniesData AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        MAX(CASE WHEN cty.kind LIKE 'Production%' THEN cn.name END) AS production_company,
        MIN(CASE WHEN cty.kind LIKE 'Distribution%' THEN cn.name END) AS distribution_company
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type cty ON mc.company_type_id = cty.id
    GROUP BY 
        mc.movie_id
),
MoviesAndActors AS (
    SELECT 
        at.title,
        at.production_year,
        COALESCE(mc.company_names, 'No companies') AS companies,
        RANK() OVER (PARTITION BY at.production_year ORDER BY at.name) AS actor_rank
    FROM 
        ActorTitles at
    LEFT JOIN 
        MovieCompaniesData mc ON at.title = mc.movie_id
),
FilteredResults AS (
    SELECT 
        * 
    FROM 
        MoviesAndActors
    WHERE 
        actor_rank <= 3 OR title LIKE '%Sequel%' 
)
SELECT 
    fr.production_year,
    fr.title,
    fr.companies,
    COUNT(DISTINCT ra.person_id) OVER (PARTITION BY fr.title) AS num_actors,
    STRING_AGG(DISTINCT ra.name, ', ') AS actor_names
FROM 
    FilteredResults fr
LEFT JOIN 
    ActorTitles ra ON fr.title = ra.title
GROUP BY 
    fr.production_year, 
    fr.title, 
    fr.companies
ORDER BY 
    fr.production_year DESC, fr.title;

