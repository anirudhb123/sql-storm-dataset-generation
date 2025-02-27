WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorTitles AS (
    SELECT 
        ca.movie_id,
        ka.name,
        COUNT(DISTINCT ka.id) AS actor_count
    FROM cast_info ca
    JOIN aka_name ka ON ka.person_id = ca.person_id
    GROUP BY ca.movie_id, ka.name
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON cn.id = mc.company_id
    JOIN company_type ct ON ct.id = mc.company_type_id
),
TitleKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mt
    JOIN keyword k ON k.id = mt.keyword_id
    GROUP BY mt.movie_id
),
ActorRanks AS (
    SELECT 
        at.movie_id,
        ROW_NUMBER() OVER (ORDER BY at.actor_count DESC) AS rank
    FROM ActorTitles at
)
SELECT 
    rt.title AS "Title",
    rt.production_year AS "Year",
    ai.actor_count AS "Actor Count",
    ci.company_name AS "Production Company",
    ci.company_type AS "Company Type",
    tk.keywords AS "Keywords",
    COALESCE(CASE WHEN ar.rank IS NOT NULL THEN ar.rank ELSE 0 END, 0) AS "Actor Rank",
    CASE
        WHEN rt.production_year < 2000 THEN 'Classic'
        WHEN rt.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'New'
    END AS "Era"
FROM RankedTitles rt
LEFT JOIN ActorTitles ai ON ai.movie_id = rt.title_id
LEFT JOIN CompanyInfo ci ON ci.movie_id = rt.title_id
LEFT JOIN TitleKeywords tk ON tk.movie_id = rt.title_id
LEFT JOIN ActorRanks ar ON ar.movie_id = rt.title_id
WHERE rt.title_rank <= 5
ORDER BY rt.production_year DESC, ai.actor_count DESC NULLS LAST
LIMIT 100;
