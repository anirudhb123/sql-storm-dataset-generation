WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id,
           mt.title,
           mt.production_year,
           0 AS level
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT mt.id AS movie_id,
           mt.title,
           mt.production_year,
           mh.level + 1
    FROM aka_title mt
    INNER JOIN movie_link ml ON mt.id = ml.linked_movie_id
    INNER JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
MovieStats AS (
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           COUNT(DISTINCT c.person_id) AS num_actors,
           STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
           SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') THEN CAST(mi.info AS INTEGER) ELSE 0 END) AS total_budget
    FROM aka_title m
    LEFT JOIN cast_info c ON m.id = c.movie_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    GROUP BY m.id
),
FilteredMovieStats AS (
    SELECT ms.*,
           ROW_NUMBER() OVER (ORDER BY ms.total_budget DESC) AS budget_rank
    FROM MovieStats ms
    WHERE ms.total_budget > 1000000
),
TopMovies AS (
    SELECT *
    FROM FilteredMovieStats
    WHERE budget_rank <= 10
)
SELECT mh.movie_id,
       mh.title,
       mh.production_year,
       COALESCE(tms.num_actors, 0) AS num_actors,
       COALESCE(tms.actor_names, 'No actors available') AS actor_names,
       tms.total_budget,
       mh.level
FROM MovieHierarchy mh
LEFT JOIN TopMovies tms ON mh.movie_id = tms.movie_id
ORDER BY mh.production_year DESC, mh.title;
