WITH RECURSIVE ActorMovies AS (
    SELECT c.person_id, c.movie_id, t.title, 
           ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE a.name IS NOT NULL
      AND a.name LIKE '%Smith%'
), 
TopActors AS (
    SELECT person_id, COUNT(DISTINCT movie_id) AS total_movies
    FROM ActorMovies
    WHERE movie_rank <= 5
    GROUP BY person_id
    HAVING COUNT(DISTINCT movie_id) > 3
),
DistinctGenres AS (
    SELECT mt.movie_id, kt.keyword AS genre_keyword
    FROM movie_keyword mk
    JOIN keyword kt ON mk.keyword_id = kt.id
    JOIN movie_info mi ON mk.movie_id = mi.movie_id
    JOIN movie_companies mc ON mc.movie_id = mk.movie_id
    WHERE kt.keyword IS NOT NULL
      AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
      AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Production')
), 
RankedMovies AS (
    SELECT a.movie_id, a.title, 
           DENSE_RANK() OVER (PARTITION BY rt.role ORDER BY t.production_year DESC) AS genre_rank,
           SUM(CASE WHEN dk.genre_keyword IS NULL THEN 1 ELSE 0 END) AS absent_genres
    FROM ActorMovies a
    LEFT JOIN role_type rt ON a.person_id = rt.id
    LEFT JOIN DistinctGenres dk ON a.movie_id = dk.movie_id
    JOIN title t ON a.movie_id = t.id
    GROUP BY a.movie_id, a.title
)
SELECT t.title, COUNT(DISTINCT t.movie_id) AS related_movies_cnt, MAX(r.absent_genres) AS max_absent_genres
FROM RankedMovies r
JOIN title t ON r.movie_id = t.id
WHERE r.genre_rank <= 10
GROUP BY t.title
HAVING MAX(r.absent_genres) = 0 OR COUNT(DISTINCT t.movie_id) > 5
ORDER BY related_movies_cnt DESC
LIMIT 10;
