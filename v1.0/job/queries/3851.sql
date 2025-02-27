
WITH MovieTitles AS (
    SELECT t.id AS title_id, t.title, t.production_year, k.keyword
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
),
CastCount AS (
    SELECT c.movie_id, COUNT(c.person_id) AS cast_size
    FROM cast_info c
    GROUP BY c.movie_id
),
TopMovies AS (
    SELECT mt.title_id, mt.title, mt.production_year, cc.cast_size
    FROM MovieTitles mt
    JOIN CastCount cc ON mt.title_id = cc.movie_id
    WHERE cc.cast_size > 5
),
ActorNames AS (
    SELECT a.name, c.movie_id
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
)
SELECT tm.title, tm.production_year, 
       STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
       COALESCE(NULLIF(CAST(tm.cast_size AS TEXT), '0'), 'No Cast') AS cast_info
FROM TopMovies tm
LEFT JOIN ActorNames an ON tm.title_id = an.movie_id
GROUP BY tm.title, tm.production_year, tm.cast_size
ORDER BY tm.production_year DESC, tm.title;
