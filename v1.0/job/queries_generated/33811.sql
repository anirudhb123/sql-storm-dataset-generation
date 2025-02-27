WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           1 AS level
    FROM aka_title m
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT m.id,
           m.title,
           m.production_year,
           h.level + 1
    FROM aka_title m
    INNER JOIN MovieHierarchy h ON m.episode_of_id = h.movie_id
),
ActorStats AS (
    SELECT a.person_id,
           a.name,
           COUNT(DISTINCT c.movie_id) AS movie_count,
           ARRAY_AGG(DISTINCT m.title) AS movies,
           ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rank
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title m ON c.movie_id = m.id
    GROUP BY a.person_id, a.name
),
CompanyStats AS (
    SELECT c.name AS company_name,
           COUNT(DISTINCT mc.movie_id) AS produced_movies,
           STRING_AGG(DISTINCT m.title, ', ') AS movies
    FROM company_name c
    JOIN movie_companies mc ON c.id = mc.company_id
    JOIN aka_title m ON mc.movie_id = m.id
    GROUP BY c.name
),
MovieInfo AS (
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           COALESCE(COUNT(mi.id), 0) AS info_count
    FROM aka_title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    GROUP BY m.id
)
SELECT mh.movie_id,
       mh.title,
       mh.production_year,
       COALESCE(as.actor_count, 0) AS actor_count,
       COALESCE(cs.produced_movies, 0) AS company_count,
       mi.info_count,
       ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.movie_id) AS year_rank
FROM MovieHierarchy mh
LEFT JOIN (
    SELECT m.id AS movie_id,
           COUNT(DISTINCT c.person_id) AS actor_count
    FROM aka_title m
    JOIN cast_info c ON m.id = c.movie_id
    GROUP BY m.id
) as AS actorStats ON mh.movie_id = actorStats.movie_id
LEFT JOIN CompanyStats cs ON mh.movie_id IN (SELECT movie_id FROM movie_companies WHERE company_id IN (SELECT id FROM company_name))
LEFT JOIN MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE mh.production_year >= 2000
ORDER BY mh.production_year, mh.movie_id;
