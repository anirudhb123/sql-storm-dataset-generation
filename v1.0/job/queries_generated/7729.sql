WITH ActorMovies AS (
    SELECT a.person_id, a.name AS actor_name, c.movie_id, t.title AS movie_title, t.production_year
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN title t ON c.movie_id = t.id
),
MovieDetails AS (
    SELECT m.movie_id, m.note AS movie_note, GROUP_CONCAT(k.keyword, ', ') AS keywords
    FROM movie_info m
    JOIN movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.movie_id, m.note
),
CompanyInfo AS (
    SELECT mc.movie_id, cn.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
Combined AS (
    SELECT am.actor_name, am.movie_title, am.production_year, md.movie_note, ci.company_name, ci.company_type, md.keywords
    FROM ActorMovies am
    JOIN MovieDetails md ON am.movie_id = md.movie_id
    JOIN CompanyInfo ci ON am.movie_id = ci.movie_id
)
SELECT actor_name, movie_title, production_year, movie_note, company_name, company_type, keywords
FROM Combined
WHERE production_year >= 2000
ORDER BY production_year DESC, actor_name;
