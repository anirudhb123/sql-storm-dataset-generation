WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.movie_id, mt.title, mt.production_year, 
           0 AS level, 
           CAST(mt.title AS VARCHAR(255)) AS full_path
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT m.movie_id, m.title, m.production_year, 
           mh.level + 1 AS level, 
           CAST(mh.full_path || ' > ' || m.title AS VARCHAR(255))
    FROM movie_link ml
    JOIN aka_title m ON ml.linked_movie_id = m.movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
TopMovies AS (
    SELECT DISTINCT m.title, m.production_year, 
           COUNT(DISTINCT ci.person_id) AS actor_count
    FROM MovieHierarchy mh
    JOIN complete_cast cc ON mh.movie_id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY m.title, m.production_year
    HAVING COUNT(DISTINCT ci.person_id) > 10
),
TopActors AS (
    SELECT CA.person_id, CA.role_id, 
           COUNT(DISTINCT title.title) AS num_movies,
           STRING_AGG(DISTINCT tit.title, ', ') AS movies
    FROM cast_info CA
    JOIN aka_title tit ON CA.movie_id = tit.movie_id
    GROUP BY CA.person_id, CA.role_id
    HAVING COUNT(DISTINCT tit.id) > 5
)
SELECT t.title AS movie_title, 
       t.production_year AS year, 
       ta.person_id AS actor_id, 
       COALESCE(ta.num_movies, 0) AS movie_count,
       COALESCE(ta.movies, 'None') AS movies_played
FROM TopMovies t
LEFT JOIN TopActors ta ON t.actor_count = ta.num_movies
WHERE t.production_year IS NOT NULL
ORDER BY t.production_year DESC, movie_title;
