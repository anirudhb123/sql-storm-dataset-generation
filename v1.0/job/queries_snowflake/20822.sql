
WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, COALESCE(cu.name, 'Unknown') AS company_name, 
           CASE WHEN m.production_year IS NULL THEN 'Unknown Year' 
                WHEN m.production_year < 2000 THEN 'Before 2000' 
                ELSE 'After 2000' END AS production_period,
           ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank
    FROM aka_title m
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_name cu ON mc.company_id = cu.id
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
base_cast AS (
    SELECT DISTINCT ci.movie_id, COALESCE(a.name, 'Unnamed Actor') AS actor_name, 
           RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM cast_info ci
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    WHERE ci.movie_id IS NOT NULL
),
expanded_cast AS (
    SELECT mh.movie_id, mh.title, mh.production_year, mh.company_name, mh.production_period, 
           bc.actor_name, bc.actor_rank
    FROM movie_hierarchy mh
    LEFT JOIN base_cast bc ON mh.movie_id = bc.movie_id
)
SELECT ec.movie_id, ec.title, ec.production_year, ec.company_name, ec.production_period,
       COUNT(ec.actor_name) AS total_actors,
       LISTAGG(DISTINCT ec.actor_name, ', ') AS actor_names,
       CASE WHEN AVG(CASE WHEN ec.actor_rank IS NOT NULL THEN 1 ELSE NULL END) > 5 
            THEN 'Superstar' 
            ELSE 'Regular' END AS status
FROM expanded_cast ec
GROUP BY ec.movie_id, ec.title, ec.production_year, ec.company_name, ec.production_period
HAVING COUNT(ec.actor_name) > 5 OR MAX(ec.production_year) IS NULL
ORDER BY ec.production_year DESC NULLS LAST, total_actors DESC;
