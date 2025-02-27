WITH Recursive ActorMovies AS (
    SELECT a.id AS actor_id,
           ak.name AS actor_name,
           c.movie_id,
           t.title,
           nt.kind AS movie_kind,
           COALESCE(t.production_year, 0) AS production_year,
           ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn
    FROM aka_name ak
    JOIN cast_info c ON ak.person_id = c.person_id
    JOIN title t ON c.movie_id = t.id
    JOIN kind_type nt ON t.kind_id = nt.id
    JOIN name a ON ak.person_id = a.imdb_id
    WHERE ak.name IS NOT NULL AND ak.name <> ''
    UNION ALL
    SELECT am.actor_id,
           am.actor_name,
           mm.movie_id,
           mm.title,
           nt2.kind AS movie_kind,
           COALESCE(mm.production_year, 0) AS production_year,
           ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY mm.production_year DESC) AS rn
    FROM ActorMovies am
    JOIN movie_link ml ON am.movie_id = ml.movie_id
    JOIN title mm ON ml.linked_movie_id = mm.id
    JOIN kind_type nt2 ON mm.kind_id = nt2.id
    WHERE am.production_year < mm.production_year
)
SELECT actor_id,
       actor_name,
       COUNT(movie_id) AS number_of_movies,
       STRING_AGG(DISTINCT title, ', ') AS movie_titles,
       MAX(production_year) AS last_movie_year,
       SUM(CASE WHEN movie_kind = 'feature' THEN 1 ELSE 0 END) AS feature_count,
       SUM(CASE WHEN movie_kind = 'short' THEN 1 ELSE 0 END) AS short_count,
       AVG(production_year) FILTER (WHERE production_year > 2000) AS avg_production_after_2000
FROM ActorMovies
WHERE rn = 1
GROUP BY actor_id, actor_name
ORDER BY number_of_movies DESC,
         last_movie_year DESC
LIMIT 50;

-- Further insights
WITH PopularGenres AS (
    SELECT t.kind_id,
           COUNT(DISTINCT c.person_id) AS num_actors_in_genre
    FROM title t
    JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.kind_id
),
RecentMovies AS (
    SELECT t.title,
           t.production_year,
           nt.kind AS movie_kind
    FROM title t
    JOIN kind_type nt ON t.kind_id = nt.id
    WHERE t.production_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 3
)
SELECT pg.kind_id,
       pg.num_actors_in_genre,
       COUNT(rm.title) AS recent_movies_count
FROM PopularGenres pg
LEFT JOIN RecentMovies rm ON pg.kind_id = rm.kind_id
GROUP BY pg.kind_id, pg.num_actors_in_genre
HAVING COUNT(rm.title) > 5
ORDER BY pg.num_actors_in_genre DESC;
