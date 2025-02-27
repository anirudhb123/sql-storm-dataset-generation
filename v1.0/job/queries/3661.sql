
WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        ak.name,
        COUNT(ci.movie_id) AS movie_count,
        DENSE_RANK() OVER (ORDER BY COUNT(ci.movie_id) DESC) AS actor_rank
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    GROUP BY ak.name
    HAVING COUNT(ci.movie_id) > 5
),
MovieCompanies AS (
    SELECT 
        at.title,
        c.name AS company_name,
        ct.kind AS company_type,
        COALESCE(ct.kind, 'Unknown') AS company_type_display
    FROM aka_title at
    JOIN movie_companies mc ON at.movie_id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rt.title, 
    rt.production_year, 
    ta.name AS top_actor, 
    mc.company_name, 
    mc.company_type_display
FROM RankedTitles rt
LEFT JOIN TopActors ta ON rt.year_rank = ta.actor_rank
LEFT JOIN MovieCompanies mc ON mc.title = rt.title
WHERE rt.production_year >= 2000
ORDER BY rt.production_year DESC, ta.movie_count DESC NULLS LAST
LIMIT 50;
