WITH RecursiveMovies AS (
    SELECT mt.id AS movie_id, 
           mt.title AS movie_title, 
           mt.production_year, 
           CASE 
               WHEN mt.production_year IS NULL THEN 'Unknown Year' 
               ELSE CAST(mt.production_year AS TEXT) 
           END AS production_year_string
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT mt.id AS movie_id, 
           mt.title AS movie_title, 
           mt.production_year, 
           'Sequel to ' || pm.movie_title || ' (' || COALESCE(pm.production_year::TEXT, 'Unknown') || ')' AS production_year_string
    FROM RecursiveMovies pm
    JOIN aka_title mt ON pm.movie_id = mt.episode_of_id
),
ActorRoles AS (
    SELECT ci.movie_id,
           ak.name AS actor_name,
           rt.role AS role_title,
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rt ON ci.role_id = rt.id
    WHERE ak.name IS NOT NULL 
    AND ak.name != ''
),
TopMovies AS (
    SELECT movie_id, 
           COUNT(DISTINCT actor_name) AS total_actors,
           STRING_AGG(DISTINCT actor_name, ', ') AS actor_list
    FROM ActorRoles
    GROUP BY movie_id
    HAVING COUNT(DISTINCT actor_name) > 5
),
MovieDetails AS (
    SELECT rm.movie_id,
           rm.movie_title,
           rm.production_year_string,
           COALESCE(tm.total_actors, 0) AS total_actors,
           tm.actor_list
    FROM RecursiveMovies rm
    LEFT JOIN TopMovies tm ON rm.movie_id = tm.movie_id
)
SELECT md.movie_title, 
       md.production_year_string, 
       md.total_actors, 
       md.actor_list,
       CASE 
           WHEN md.total_actors > 10 THEN 'Blockbuster'
           WHEN md.total_actors BETWEEN 6 AND 10 THEN 'Moderate Success'
           ELSE 'Indie Film'
       END AS success_category
FROM MovieDetails md
ORDER BY md.production_year_string DESC, md.movie_title 
FETCH FIRST 20 ROWS ONLY;
