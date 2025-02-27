WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, 
           m.title AS movie_title,
           0 AS level
    FROM aka_title m
    WHERE m.production_year = 2023
    
    UNION ALL
    
    SELECT m2.id AS movie_id, 
           m2.title AS movie_title,
           mh.level + 1 AS level
    FROM movie_link ml
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m2 ON ml.linked_movie_id = m2.id
),
RankedCast AS (
    SELECT c.movie_id, 
           a.name AS actor_name,
           ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank,
           COUNT(*) OVER (PARTITION BY c.movie_id) AS total_actors
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
),
FilteredMovies AS (
    SELECT mh.movie_id,
           mh.movie_title,
           rc.actor_name,
           rc.actor_rank,
           rc.total_actors
    FROM MovieHierarchy mh
    LEFT JOIN RankedCast rc ON mh.movie_id = rc.movie_id
)
SELECT f.movie_id,
       f.movie_title,
       COALESCE(f.actor_name, 'Unknown Actor') AS actor_name,
       f.actor_rank,
       f.total_actors, 
       CASE WHEN f.actor_rank IS NULL THEN 'No Cast' 
            ELSE f.actor_name END AS cast_status,
       (SELECT COUNT(DISTINCT mc.company_id) 
        FROM movie_companies mc 
        WHERE mc.movie_id = f.movie_id 
          AND mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')) AS production_companies,
       SUM(CASE WHEN rc.total_actors > 0 THEN 1 ELSE 0 END) OVER () AS total_movies_with_actors
FROM FilteredMovies f
ORDER BY f.movie_id, f.actor_rank NULLS LAST;

