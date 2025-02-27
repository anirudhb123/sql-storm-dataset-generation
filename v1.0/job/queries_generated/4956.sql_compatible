
WITH ActorMovies AS (
    SELECT a.id AS actor_id, a.name AS actor_name, 
           COUNT(DISTINCT ci.movie_id) AS total_movies,
           STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title t ON ci.movie_id = t.movie_id
    WHERE a.name IS NOT NULL
    GROUP BY a.id, a.name
),
CompanyMovies AS (
    SELECT mc.movie_id, c.name AS company_name, 
           ct.kind AS company_type, 
           COUNT(DISTINCT mc.company_id) AS total_companies
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, c.name, ct.kind
),
RankedMovies AS (
    SELECT t.id AS movie_id, t.title, 
           COALESCE(SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END), 0) AS actor_count,
           ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END), 0) DESC) AS movie_rank
    FROM aka_title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY t.id, t.title
)
SELECT rm.movie_id, rm.title, rm.movie_rank, 
       am.actor_name, am.total_movies, am.movie_titles,
       cm.company_name, cm.company_type, cm.total_companies
FROM RankedMovies rm
LEFT JOIN ActorMovies am ON am.total_movies > 1 
    AND am.actor_id IN (
        SELECT ci.person_id 
        FROM cast_info ci 
        WHERE ci.movie_id = rm.movie_id
    )
LEFT JOIN CompanyMovies cm ON cm.movie_id = rm.movie_id
WHERE rm.movie_rank <= 10
ORDER BY rm.movie_rank, am.total_movies DESC;
