WITH ActorTitles AS (
    SELECT a.name AS actor_name, t.title AS movie_title, t.production_year 
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE t.production_year >= 2000
),
MovieCompanies AS (
    SELECT t.title AS movie_title, c.name AS company_name, ct.kind AS company_type 
    FROM aka_title t
    JOIN movie_companies mc ON t.movie_id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
KeywordMovies AS (
    SELECT t.title AS movie_title, k.keyword AS keyword 
    FROM aka_title t
    JOIN movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.phonetic_code IS NOT NULL
),
CombinedData AS (
    SELECT a.actor_name, m.movie_title, m.company_name, m.company_type, k.keyword 
    FROM ActorTitles a
    JOIN MovieCompanies m ON a.movie_title = m.movie_title
    JOIN KeywordMovies k ON a.movie_title = k.movie_title
)
SELECT actor_name, movie_title, company_name, company_type, keyword 
FROM CombinedData
ORDER BY actor_name, movie_title;
