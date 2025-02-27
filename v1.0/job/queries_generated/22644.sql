WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        STRING_AGG(DISTINCT r.role, ', ') AS roles,
        COUNT(DISTINCT m.movie_id) AS movie_count
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    JOIN RankedMovies m ON c.movie_id = m.movie_id
    GROUP BY c.person_id, a.name
),
TopActors AS (
    SELECT 
        ai.actor_name,
        ai.movie_count,
        RANK() OVER (ORDER BY ai.movie_count DESC) AS actor_rank
    FROM ActorInfo ai
    WHERE ai.movie_count > 5
)
SELECT 
    t.movie_id,
    t.title,
    t.production_year,
    COALESCE(ta.actor_name, 'No Actors Found') AS actor_name,
    COALESCE(ta.movie_count, 0) AS actor_movie_count,
    CASE 
        WHEN ta.actor_rank IS NULL THEN 'N/A'
        ELSE CAST(ta.actor_rank AS text)
    END AS actor_rank
FROM RankedMovies t
LEFT JOIN TopActors ta ON t.title_rank = ta.actor_rank
WHERE t.total_movies > 10
  AND (t.production_year BETWEEN 1990 AND 2000 OR t.production_year IS NULL)
  AND (t.title IS NOT NULL AND LENGTH(t.title) > 0)
ORDER BY t.production_year, t.title;

-- Consider aggregate functions and use of NULL logic within the context of roles and movies 
-- while ensuring some bizarre case such as actor's rank turning 'N/A' if they are 
-- not in the top actor list.
