WITH ActorMovies AS (
    SELECT a.id AS actor_id, 
           a.name AS actor_name, 
           t.title AS movie_title, 
           t.production_year, 
           ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
),
TopMovies AS (
    SELECT actor_id, 
           actor_name, 
           movie_title, 
           production_year 
    FROM ActorMovies 
    WHERE rn <= 5
),
MovieGenres AS (
    SELECT t.id AS movie_id, 
           GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS genres
    FROM aka_title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id
)
SELECT a.actor_name, 
       tm.movie_title, 
       tm.production_year, 
       mg.genres
FROM TopMovies tm
LEFT JOIN MovieGenres mg ON tm.movie_title = mg.movie_title
JOIN aka_name a ON tm.actor_id = a.id
WHERE a.name IS NOT NULL
ORDER BY tm.actor_name, tm.production_year DESC;
