WITH RECURSIVE ActorHierarchy AS (
    SELECT ci.person_id AS actor_id, ct.kind AS cast_type, 
           t.title AS movie_title, t.production_year,
           ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY t.production_year DESC) AS rank
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    JOIN aka_title at ON ci.movie_id = at.movie_id
    JOIN kind_type kt ON at.kind_id = kt.id
    JOIN title t ON at.movie_id = t.id
    JOIN comp_cast_type ct ON ci.role_id = ct.id
    WHERE ct.kind ILIKE 'actor'
),
FilteredMovies AS (
    SELECT m.movie_id, COUNT(DISTINCT m.company_id) AS total_companies,
           STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM movie_companies m
    JOIN company_name cn ON m.company_id = cn.id
    GROUP BY m.movie_id
),
RankedMovies AS (
    SELECT ah.actor_id, ah.movie_title, ah.production_year, 
           ah.rank, fm.total_companies, fm.companies
    FROM ActorHierarchy ah
    LEFT JOIN FilteredMovies fm ON ah.movie_title = (SELECT title FROM title WHERE id = fm.movie_id)
    WHERE ah.rank < 5
)
SELECT ah.actor_id, an.name, COUNT(DISTINCT rm.movie_title) AS num_movies,
       AVG(rm.total_companies) AS avg_companies,
       STRING_AGG(DISTINCT rm.companies, '; ') AS companies_in_movies
FROM RankedMovies rm
JOIN aka_name an ON rm.actor_id = an.person_id
GROUP BY ah.actor_id, an.name
ORDER BY num_movies DESC, avg_companies DESC
LIMIT 10;


