WITH RecursiveTitleCTE AS (
    SELECT t.id AS title_id, t.title, t.production_year, t.kind_id, 
           ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT m.movie_id, m.company_id, m.note,
           COALESCE(cn.name, 'Unknown Company') AS company_name,
           COALESCE(ct.kind, 'Unknown Type') AS company_type
    FROM movie_companies m
    LEFT JOIN company_name cn ON m.company_id = cn.id
    LEFT JOIN company_type ct ON m.company_type_id = ct.id
),
TopActors AS (
    SELECT a.person_id, ak.name,
           COUNT(DISTINCT ci.movie_id) AS movie_count,
           ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_rank
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY a.person_id, ak.name
    HAVING COUNT(DISTINCT ci.movie_id) > 5
)
SELECT r.title, r.production_year, md.company_name, md.company_type,
       ta.name AS actor_name, ta.movie_count
FROM RecursiveTitleCTE r
LEFT JOIN MovieDetails md ON r.title_id = md.movie_id
JOIN TopActors ta ON ta.movie_count = (
    SELECT MAX(movie_count)
    FROM TopActors
)
WHERE r.title_rank <= 10
AND r.production_year > 2000
ORDER BY r.production_year DESC, r.title;
