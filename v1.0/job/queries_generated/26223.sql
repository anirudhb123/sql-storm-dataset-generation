WITH ActorMovies AS (
    SELECT a.name AS actor_name,
           t.title AS movie_title,
           t.production_year,
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY a.name, t.title, t.production_year
), MovieDetails AS (
    SELECT title.title AS movie_title,
           COUNT(DISTINCT ci.person_id) AS cast_count,
           STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM title
    JOIN movie_companies mc ON title.id = mc.movie_id
    JOIN company_name co ON mc.company_id = co.id
    JOIN cast_info ci ON title.id = ci.movie_id
    GROUP BY title.title
), Benchmark AS (
    SELECT am.actor_name,
           am.movie_title,
           am.production_year,
           am.keywords,
           md.cast_count,
           md.companies
    FROM ActorMovies am
    JOIN MovieDetails md ON am.movie_title = md.movie_title
)
SELECT actor_name,
       movie_title,
       production_year,
       keywords,
       cast_count,
       companies
FROM Benchmark
WHERE production_year >= 2000
ORDER BY production_year DESC, cast_count DESC;
