
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        ca.person_id,
        COUNT(DISTINCT ca.movie_id) AS movie_count
    FROM cast_info ca
    GROUP BY ca.person_id
),
CompanyMovieCounts AS (
    SELECT 
        mc.company_id,
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM movie_companies mc
    WHERE mc.company_type_id IS NOT NULL
    GROUP BY mc.company_id
),
TopActors AS (
    SELECT 
        ak.name,
        ac.movie_count
    FROM aka_name ak
    JOIN ActorMovieCounts ac ON ak.person_id = ac.person_id
    WHERE ac.movie_count > 5
),
TopCompanies AS (
    SELECT 
        cn.name,
        cc.movie_count
    FROM company_name cn
    JOIN CompanyMovieCounts cc ON cn.id = cc.company_id
    WHERE cc.movie_count > 10
)

SELECT 
    t.title,
    t.production_year,
    COALESCE(ta.name, 'Unknown Actor') AS actor_name,
    COALESCE(tc.name, 'Unknown Company') AS company_name
FROM RankedTitles t
LEFT JOIN TopActors ta ON t.title_id IN (
    SELECT ca.movie_id 
    FROM cast_info ca 
    WHERE ca.person_id IN (SELECT person_id FROM aka_name WHERE name IS NOT NULL)
)
LEFT JOIN TopCompanies tc ON t.title_id IN (
    SELECT mc.movie_id 
    FROM movie_companies mc 
    WHERE mc.company_id IN (SELECT id FROM company_name WHERE name IS NOT NULL)
)
WHERE t.title_rank <= 3 
AND (t.title LIKE '%Action%' OR t.title LIKE '%Drama%')
GROUP BY t.title, t.production_year, ta.name, tc.name, t.title_rank
ORDER BY t.production_year DESC, t.title;
