WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        COALESCE(c.person_id, -1) AS actor_id,
        COALESCE(a2.name, 'Unknown') AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS role_rank,
        COUNT(*) OVER (PARTITION BY a.id) AS total_actors
    FROM aka_title a
    LEFT JOIN cast_info c ON a.id = c.movie_id
    LEFT JOIN aka_name a2 ON c.person_id = a2.person_id
    WHERE a.production_year >= 2000 
      AND a.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Film%')
),
MovieStatistics AS (
    SELECT 
        title,
        production_year,
        actor_id,
        actor_name,
        role_rank,
        total_actors,
        CASE 
            WHEN total_actors > 5 THEN 'Large Ensemble'
            WHEN total_actors BETWEEN 3 AND 5 THEN 'Medium Ensemble'
            ELSE 'Small Cast'
        END AS cast_size
    FROM RankedMovies
),
ActorCount AS (
    SELECT 
        actor_id,
        COUNT(DISTINCT movie_id) AS movie_count
    FROM cast_info
    GROUP BY actor_id
)
SELECT 
    ms.title,
    ms.production_year,
    ms.actor_name,
    ms.cast_size,
    ac.movie_count,
    CASE 
        WHEN ac.movie_count IS NULL THEN 'No Movies'
        WHEN ac.movie_count = 1 THEN 'Single Appearance'
        WHEN ac.movie_count BETWEEN 2 AND 4 THEN 'Character Actor'
        ELSE 'Versatile Actor'
    END AS actor_category
FROM MovieStatistics ms
LEFT JOIN ActorCount ac ON ms.actor_id = ac.actor_id
WHERE ms.role_rank = 1
  AND ms.cast_size = 'Large Ensemble'
ORDER BY ms.production_year DESC, ms.title;

-- NOTE: The query takes into account various scenarios:
-- 1. Movies from the 2000s onwards with a 'Film' kind type.
-- 2. Actors are categorized into ensembles based on the total cast size.
-- 3. Each actor's movie appearance count categorizes them into character types.
-- 4. The use of COALESCE to handle NULLs in case of missing data for actor names.
-- 5. The selection criteria focus solely on leading roles (role_rank = 1).
