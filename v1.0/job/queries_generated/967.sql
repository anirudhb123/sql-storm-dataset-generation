WITH RecursiveCTE AS (
    SELECT p.id, n.name, a.title, a.production_year,
           ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY a.production_year DESC) as rn
    FROM aka_name n
    JOIN cast_info c ON c.person_id = n.person_id
    JOIN aka_title a ON a.movie_id = c.movie_id
    JOIN name p ON p.id = n.person_id
    WHERE a.production_year IS NOT NULL
),
AggregatedMovies AS (
    SELECT c.id AS company_id, cn.name AS company_name, 
           ARRAY_AGG(DISTINCT t.title) AS movie_titles,
           COUNT(DISTINCT t.id) AS movie_count
    FROM movie_companies mc
    JOIN company_name cn ON cn.id = mc.company_id
    JOIN title t ON t.id = mc.movie_id
    GROUP BY c.id, cn.name
)
SELECT r.name AS actor_name, 
       STRING_AGG(r.title || ' (' || r.production_year || ')', ', ') AS films,
       COALESCE(am.movie_count, 0) AS total_movies,
       am.movie_titles AS movie_titles
FROM RecursiveCTE r
LEFT JOIN AggregatedMovies am ON am.company_id = (SELECT mc.company_id 
                                                   FROM movie_companies mc
                                                   JOIN title t ON t.id = mc.movie_id
                                                   WHERE t.id IN (SELECT movie_id FROM cast_info WHERE person_id = r.id)
                                                   LIMIT 1)
WHERE r.rn = 1
GROUP BY r.name, am.movie_count, am.movie_titles
HAVING COUNT(r.title) > 2
ORDER BY total_movies DESC
LIMIT 10;
