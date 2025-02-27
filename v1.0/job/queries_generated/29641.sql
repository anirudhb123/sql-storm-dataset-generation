WITH ActorMovies AS (
    SELECT ak.name AS actor_name,
           t.title AS movie_title,
           t.production_year,
           GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    WHERE ak.name IS NOT NULL
    GROUP BY ak.name, t.title, t.production_year
),
CompanyMovies AS (
    SELECT cn.name AS company_name,
           t.title AS movie_title,
           t.production_year
    FROM company_name cn
    JOIN movie_companies mc ON cn.id = mc.company_id
    JOIN title t ON mc.movie_id = t.id
    WHERE cn.name IS NOT NULL
),
UniqueMovies AS (
    SELECT DISTINCT movie_title, production_year
    FROM ActorMovies
    UNION
    SELECT DISTINCT movie_title, production_year
    FROM CompanyMovies
)

SELECT u.movie_title,
       u.production_year,
       COUNT(DISTINCT am.actor_name) AS actor_count,
       COUNT(DISTINCT cm.company_name) AS company_count,
       GROUP_CONCAT(DISTINCT am.keywords) AS all_keywords
FROM UniqueMovies u
LEFT JOIN ActorMovies am ON u.movie_title = am.movie_title AND u.production_year = am.production_year
LEFT JOIN CompanyMovies cm ON u.movie_title = cm.movie_title AND u.production_year = cm.production_year
GROUP BY u.movie_title, u.production_year
ORDER BY u.production_year DESC, u.movie_title;
