
WITH RankedTitles AS (
    SELECT t.id,
           t.title,
           t.production_year,
           ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),
CompanyMovieInfo AS (
    SELECT m.movie_id,
           c.name AS company_name,
           ct.kind AS company_type,
           COUNT(*) AS total_movies
    FROM movie_companies m
    JOIN company_name c ON m.company_id = c.id
    JOIN company_type ct ON m.company_type_id = ct.id
    GROUP BY m.movie_id, c.name, ct.kind
),
ActorRoles AS (
    SELECT a.person_id,
           COUNT(DISTINCT ci.movie_id) AS movies_played,
           STRING_AGG(DISTINCT r.role || ' in ' || t.title, '; ') AS roles
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.id
    JOIN title t ON ci.movie_id = t.id
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY a.person_id
)
SELECT rt.production_year,
       rt.title,
       rt.year_rank,
       crm.company_name,
       crm.company_type,
       ar.movies_played,
       ar.roles
FROM RankedTitles rt
LEFT JOIN CompanyMovieInfo crm ON rt.id = crm.movie_id
LEFT JOIN ActorRoles ar ON rt.id IN (SELECT ci.movie_id FROM cast_info ci WHERE ci.movie_id = rt.id)
WHERE rt.year_rank <= 5
  AND (crm.total_movies > 1 OR crm.total_movies IS NULL)
ORDER BY rt.production_year DESC, rt.title
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
