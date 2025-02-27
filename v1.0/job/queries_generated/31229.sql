WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           0 AS depth
    FROM aka_title m
    WHERE m.production_year >= 2000
    UNION ALL
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           mh.depth + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
GenreCount AS (
    SELECT mt.movie_id,
           COUNT(DISTINCT kw.id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword kw ON mk.keyword_id = kw.id
    JOIN aka_title mt ON mk.movie_id = mt.id
    GROUP BY mt.movie_id
),
TopActorMovies AS (
    SELECT c.movie_id,
           a.name AS actor_name,
           COUNT(DISTINCT c.person_id) AS actor_count
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE a.name IS NOT NULL
    GROUP BY c.movie_id, a.name
    HAVING COUNT(DISTINCT c.person_id) > 1
),
MovieDetails AS (
    SELECT mh.movie_id,
           mh.title,
           mh.production_year,
           gc.keyword_count,
           tam.actor_name,
           tam.actor_count
    FROM MovieHierarchy mh
    LEFT JOIN GenreCount gc ON mh.movie_id = gc.movie_id
    LEFT JOIN TopActorMovies tam ON mh.movie_id = tam.movie_id
)
SELECT md.title,
       md.production_year,
       COALESCE(md.keyword_count, 0) AS keyword_count,
       COALESCE(md.actor_name, 'Unknown') AS lead_actor,
       COALESCE(md.actor_count, 0) AS actor_count
FROM MovieDetails md
WHERE (md.production_year >= 2000 AND md.keyword_count > 0)
   OR (md.production_year < 2000 AND md.actor_count > 1)
ORDER BY md.production_year DESC, keyword_count DESC, actor_count DESC;
