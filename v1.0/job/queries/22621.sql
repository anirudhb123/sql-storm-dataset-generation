WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM cast_info ci
    GROUP BY ci.person_id
),
TopActors AS (
    SELECT 
        a.person_id,
        a.name,
        amc.movie_count
    FROM aka_name a
    JOIN ActorMovieCount amc ON a.person_id = amc.person_id
    WHERE amc.movie_count > (
        SELECT AVG(movie_count) 
        FROM ActorMovieCount
    )
),
CompanyMovieDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tt.title,
    tt.production_year,
    ta.name AS actor_name,
    COUNT(DISTINCT cm.movie_id) AS total_movies,
    SUM(CASE WHEN cm.company_type = 'Distributor' THEN 1 ELSE 0 END) AS distributor_count,
    STRING_AGG(DISTINCT cm.company_name, ', ') AS companies_involved
FROM RankedTitles tt
JOIN cast_info ci ON ci.movie_id = tt.title_id
JOIN TopActors ta ON ci.person_id = ta.person_id
LEFT JOIN CompanyMovieDetails cm ON cm.movie_id = tt.title_id
WHERE tt.title_rank <= 5
GROUP BY tt.title, tt.production_year, ta.name
HAVING COUNT(DISTINCT cm.movie_id) > 1
ORDER BY tt.production_year DESC, total_movies DESC
LIMIT 50;
