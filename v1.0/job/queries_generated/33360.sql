WITH RECURSIVE ActorHierarchy AS (
    SELECT ci.person_id, 
           COUNT(*) AS movie_count,
           ARRAY[ci.movie_id] AS movies_list
    FROM cast_info ci
    GROUP BY ci.person_id
    HAVING COUNT(*) > 1
), 

MovieDetails AS (
    SELECT mt.id AS movie_id, 
           mt.title, 
           mt.production_year, 
           mt.kind_id,
           ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY mt.id
), 

DirectorMovies AS (
    SELECT c.person_id,
           COUNT(DISTINCT c.movie_id) AS directed_movies_count
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    WHERE r.role LIKE '%Director%'
    GROUP BY c.person_id
), 

CombinedDetails AS (
    SELECT md.movie_id,
           md.title,
           md.production_year,
           md.cast_count,
           array_agg(DISTINCT a.name) AS actors,
           dm.directed_movies_count,
           CASE 
               WHEN dm.directed_movies_count IS NULL THEN 'N/A'
               ELSE dm.directed_movies_count::text
           END AS director_count,
           CASE 
               WHEN md.production_year IS NULL THEN 'Unknown Year'
               ELSE md.production_year::text
           END AS year_string
    FROM MovieDetails md
    LEFT JOIN aka_name a ON a.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = md.movie_id)
    LEFT JOIN DirectorMovies dm ON dm.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = md.movie_id) 
    GROUP BY md.movie_id, md.title, md.production_year, md.cast_count, dm.directed_movies_count
)

SELECT cd.movie_id, 
       cd.title, 
       cd.production_year, 
       cd.cast_count, 
       cd.actors, 
       cd.director_count, 
       cd.year_string,
       CASE WHEN cd.cast_count > 10 THEN 'Epic' 
            WHEN cd.cast_count BETWEEN 5 AND 10 THEN 'Moderate' 
            ELSE 'Small' END AS cast_size  
FROM CombinedDetails cd
WHERE cd.production_year >= 2000
ORDER BY cd.production_year DESC, cd.cast_count DESC;
