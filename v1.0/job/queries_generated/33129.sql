WITH RECURSIVE ActorHierarchy AS (
    SELECT c.movie_id,
           ca.person_id,
           ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY ca.nr_order) as actor_order
    FROM cast_info ca
    JOIN movie_companies mc ON ca.movie_id = mc.movie_id
    WHERE mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Production')
),
MovieDetails AS (
    SELECT t.title,
           t.production_year,
           ak.name AS actor_name,
           COUNT(DISTINCT k.keyword) AS keyword_count
    FROM aka_title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
    GROUP BY t.title, t.production_year, ak.name
),
ActorStats AS (
    SELECT movie_id,
           MIN(actor_order) AS first_actor_order,
           MAX(actor_order) AS last_actor_order,
           COUNT(*) AS total_actors
    FROM ActorHierarchy
    GROUP BY movie_id
),
FinalResults AS (
    SELECT md.title,
           md.production_year,
           as.total_actors,
           CASE WHEN as.total_actors > 5 THEN 'Ensemble Cast'
                WHEN as.total_actors = 1 THEN 'Solo Actor'
                ELSE 'Standard Cast' END AS cast_type,
           md.keyword_count
    FROM MovieDetails md
    JOIN ActorStats as ON md.movie_id = as.movie_id
)
SELECT title,
       production_year,
       total_actors,
       cast_type,
       keyword_count,
       CASE WHEN keyword_count IS NULL THEN 'No Keywords'
            ELSE keyword_count::text || ' keywords' END AS keyword_information
FROM FinalResults
ORDER BY production_year DESC, total_actors DESC;
