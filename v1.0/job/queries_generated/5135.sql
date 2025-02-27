WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ak.name AS actor_name,
        c.kind AS casting_type
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.id
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN comp_cast_type c ON ci.person_role_id = c.id
    WHERE t.production_year >= 2000
    AND k.keyword LIKE 'Action%'
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
FinalResults AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        md.actor_name,
        cd.company_name,
        cd.company_type
    FROM MovieDetails md
    LEFT JOIN CompanyDetails cd ON md.title_id = cd.movie_id
)
SELECT 
    title_id,
    title, 
    production_year, 
    actor_name, 
    COALESCE(company_name, 'Independent') AS company_name, 
    COALESCE(company_type, 'N/A') AS company_type
FROM FinalResults
ORDER BY production_year DESC, title;
