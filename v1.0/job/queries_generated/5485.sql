WITH ActorMovies AS (
    SELECT a.name AS actor_name, t.title AS movie_title, t.production_year
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.id
),
CompanyMovies AS (
    SELECT c.name AS company_name, t.title AS movie_title, t.production_year
    FROM company_name c
    JOIN movie_companies mc ON c.id = mc.company_id
    JOIN aka_title t ON mc.movie_id = t.id
),
KeywordMovies AS (
    SELECT k.keyword, t.title AS movie_title, t.production_year
    FROM keyword k
    JOIN movie_keyword mk ON k.id = mk.keyword_id
    JOIN aka_title t ON mk.movie_id = t.id
)
SELECT 
    AM.actor_name, 
    CM.company_name, 
    KM.keyword, 
    AM.movie_title, 
    AM.production_year
FROM ActorMovies AM
JOIN CompanyMovies CM ON AM.movie_title = CM.movie_title AND AM.production_year = CM.production_year
JOIN KeywordMovies KM ON AM.movie_title = KM.movie_title AND AM.production_year = KM.production_year
WHERE AM.actor_name IS NOT NULL 
  AND CM.company_name IS NOT NULL 
  AND KM.keyword IS NOT NULL
ORDER BY AM.production_year DESC, AM.actor_name, CM.company_name;
