
WITH ActorTitles AS (
    SELECT a.person_id, a.name AS actor_name, t.id AS movie_id, t.title AS movie_title, t.production_year
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title t ON ci.movie_id = t.movie_id
),
CompanyMovies AS (
    SELECT mc.movie_id, c.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
KeywordMovies AS (
    SELECT mk.movie_id, k.keyword AS movie_keyword
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
),
CompleteMovieInfo AS (
    SELECT t.title AS movie_title, t.production_year, a.actor_name, cm.company_name, cm.company_type, km.movie_keyword
    FROM aka_title t
    JOIN ActorTitles a ON t.id = a.movie_id
    JOIN CompanyMovies cm ON t.id = cm.movie_id
    JOIN KeywordMovies km ON t.id = km.movie_id
)
SELECT movie_title, production_year, 
       STRING_AGG(DISTINCT actor_name, ', ') AS actors,
       STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', ', ') AS companies,
       STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
FROM CompleteMovieInfo
GROUP BY movie_title, production_year
ORDER BY production_year DESC, movie_title;
