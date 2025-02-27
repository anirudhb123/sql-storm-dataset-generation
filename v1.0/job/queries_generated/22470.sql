WITH RecursiveActorTitles AS (
    SELECT a.id AS actor_id, t.title, t.production_year, ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rank
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE a.name IS NOT NULL
),
FilteredTitles AS (
    SELECT actor_id, title, production_year
    FROM RecursiveActorTitles
    WHERE rank <= 3 -- Get top 3 recent titles for each actor
),
CompanyInfo AS (
    SELECT mc.movie_id, cn.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
MovieKeywords AS (
    SELECT mk.movie_id, k.keyword
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
),
FinalResults AS (
    SELECT 
        a.actor_id,
        a.title,
        a.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS associated_keywords,
        STRING_AGG(DISTINCT ci.company_name, ', ') AS production_companies,
        COUNT(DISTINCT CASE WHEN ci.company_type = 'Distributor' THEN ci.company_name END) AS distributor_count
    FROM FilteredTitles a
    LEFT JOIN MovieKeywords k ON a.title = k.movie_id
    LEFT JOIN CompanyInfo ci ON a.title = ci.movie_id
    GROUP BY a.actor_id, a.title, a.production_year
)
SELECT actor_id, title, production_year, associated_keywords, production_companies, distributor_count
FROM FinalResults
WHERE associated_keywords IS NOT NULL
ORDER BY production_year DESC, actor_id;
