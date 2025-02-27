WITH RECURSIVE ActorHierarchy AS (
    SELECT c.movie_id, a.person_id, a.name, CAST(a.name AS VARCHAR) AS actor_path
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE c.nr_order = 1  -- Starting with lead actors
    UNION ALL
    SELECT c.movie_id, a.person_id, a.name, CONCAT(h.actor_path, ' -> ', a.name)
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN ActorHierarchy h ON c.movie_id = h.movie_id
    WHERE c.nr_order > 1
),

MovieCompanies AS (
    SELECT mc.movie_id, GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),

MovieKeywords AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),

ActorPerformance AS (
    SELECT ah.movie_id, ah.name AS actor_name,
           COUNT(DISTINCT c.movie_id) AS total_movies,
           ROW_NUMBER() OVER (PARTITION BY ah.person_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rank
    FROM ActorHierarchy ah
    JOIN complete_cast c ON ah.movie_id = c.movie_id
    GROUP BY ah.movie_id, ah.name
),

FinalReport AS (
    SELECT t.title, t.production_year, ap.actor_name, ap.total_movies, mc.companies, mk.keywords
    FROM title t
    LEFT JOIN ActorPerformance ap ON t.id = ap.movie_id
    LEFT JOIN MovieCompanies mc ON t.id = mc.movie_id
    LEFT JOIN MovieKeywords mk ON t.id = mk.movie_id
)

SELECT *,
       COALESCE(total_movies, 0) AS total_movies,
       COALESCE(companies, 'No Companies Found') AS companies,
       COALESCE(keywords, 'No Keywords') AS keywords
FROM FinalReport
ORDER BY production_year DESC, total_movies DESC;
