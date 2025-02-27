WITH recursive MovieCoActors AS (
    SELECT
        c1.movie_id,
        a1.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c1.movie_id ORDER BY a1.name) AS actor_rank
    FROM cast_info c1
    JOIN aka_name a1 ON c1.person_id = a1.person_id
),
CoActors AS (
    SELECT
        mc.movie_id,
        STRING_AGG(ma.actor_name, ', ') AS co_actor_names,
        COUNT(ma.actor_name) AS total_co_actors
    FROM MovieCoActors mc
    JOIN MovieCoActors ma ON mc.movie_id != ma.movie_id AND mc.actor_name != ma.actor_name
    GROUP BY mc.movie_id
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(ca.co_actor_names, 'No co-actors') AS co_actor_list,
        COALESCE(ca.total_co_actors, 0) AS co_actor_count
    FROM title t
    LEFT JOIN CoActors ca ON t.id = ca.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.co_actor_list,
    md.co_actor_count,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = t.id) AS info_count,
    (SELECT AVG(year) 
     FROM (SELECT DISTINCT production_year FROM title WHERE production_year IS NOT NULL) AS years) AS avg_production_year
FROM MovieDetails md
LEFT JOIN title t ON md.title = t.title
WHERE 
    (md.co_actor_count > 0 AND md.co_actor_count < 10) OR
    (md.production_year IS NOT NULL AND md.production_year < 2000)
ORDER BY md.production_year DESC, md.co_actor_count DESC
LIMIT 100;
