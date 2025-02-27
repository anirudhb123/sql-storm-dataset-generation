WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        tt.title AS movie_title,
        tt.production_year,
        COUNT(*) OVER (PARTITION BY a.id) AS total_movies
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN title tt ON ci.movie_id = tt.id
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies m
    JOIN company_name c ON m.company_id = c.id
    JOIN company_type ct ON m.company_type_id = ct.id
),
FinalResults AS (
    SELECT 
        am.actor_name,
        am.movie_title,
        am.production_year,
        CASE 
            WHEN cd.company_name IS NOT NULL THEN cd.company_name
            ELSE 'Independent'
        END AS production_company,
        COUNT(DISTINCT cd.company_name) OVER (PARTITION BY am.actor_name) AS company_count,
        CASE 
            WHEN am.total_movies > 5 THEN 'Prolific Actor'
            ELSE 'Emerging Talent'
        END AS actor_status
    FROM ActorMovies am
    LEFT JOIN CompanyDetails cd ON am.movie_title = cd.movie_title AND am.production_year = cd.production_year
)
SELECT 
    r.title_id,
    r.title,
    r.production_year,
    fr.actor_name,
    fr.production_company,
    fr.actor_status
FROM RankedTitles r
LEFT JOIN FinalResults fr ON r.title = fr.movie_title AND r.production_year = fr.production_year
WHERE r.title_rank <= 10
ORDER BY r.production_year DESC, r.title;
