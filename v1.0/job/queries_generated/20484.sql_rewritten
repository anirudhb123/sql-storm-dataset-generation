WITH MovieActor AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.id
    WHERE t.production_year IS NOT NULL
      AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
),

ActorMovieCount AS (
    SELECT 
        actor_id,
        COUNT(movie_id) AS movie_count
    FROM MovieActor
    GROUP BY actor_id
),

PopularActors AS (
    SELECT 
        ma.actor_id,
        ma.actor_name,
        ac.movie_count
    FROM MovieActor ma
    JOIN ActorMovieCount ac ON ma.actor_id = ac.actor_id
    WHERE ac.movie_count > (
        SELECT AVG(movie_count) FROM ActorMovieCount
    )
),

NULLChecks AS (
    SELECT DISTINCT
        a.actor_id,
        COALESCE(NULLIF(a.actor_name, ''), 'Unknown Actor') AS normalized_actor_name
    FROM PopularActors a
)

SELECT 
    n.normalized_actor_name,
    COUNT('1') AS blockbuster_count,
    STRING_AGG(DISTINCT m.title, ', ') AS blockbuster_titles
FROM NULLChecks n
LEFT JOIN cast_info c ON n.actor_id = c.person_id
LEFT JOIN aka_title m ON c.movie_id = m.id
WHERE m.production_year >= 2000
  AND m.production_year <= EXTRACT(YEAR FROM cast('2024-10-01' as date))
  AND m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
GROUP BY n.normalized_actor_name
HAVING COUNT('1') > 5
ORDER BY COUNT('1') DESC
LIMIT 10;