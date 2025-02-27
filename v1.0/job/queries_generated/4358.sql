WITH MovieTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year >= 2000
),
ActorNames AS (
    SELECT 
        a.person_id,
        MAX(a.name) AS actor_name
    FROM aka_name a
    GROUP BY a.person_id
),
MovieCasting AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS actor_count
    FROM cast_info c
    GROUP BY c.movie_id
),
TopMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        mc.actor_count
    FROM MovieTitles mt
    JOIN MovieCasting mc ON mt.title_id = mc.movie_id
    WHERE mc.actor_count > 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    ci.companies,
    ac.actor_name,
    COUNT(DISTINCT keyword.keyword) AS associated_keywords
FROM TopMovies tm
LEFT JOIN CompanyInfo ci ON tm.movie_id = ci.movie_id
LEFT JOIN cast_info c ON c.movie_id = tm.movie_id
LEFT JOIN ActorNames ac ON ac.person_id = c.person_id
LEFT JOIN movie_keyword keyword ON keyword.movie_id = tm.movie_id
WHERE tm.actor_count IS NOT NULL
GROUP BY tm.title, tm.production_year, ci.companies, ac.actor_name
HAVING COUNT(DISTINCT keyword.keyword) > 2
ORDER BY tm.production_year DESC, tm.title;
