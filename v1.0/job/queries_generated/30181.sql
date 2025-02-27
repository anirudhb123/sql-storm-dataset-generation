WITH RECURSIVE ActorHierarchy AS (
    SELECT ci.person_id, a.name AS actor_name, ci.movie_id, 1 AS level
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE a.name IS NOT NULL
    UNION ALL
    SELECT ci.person_id, a.name AS actor_name, ci.movie_id, ah.level + 1
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN ActorHierarchy ah ON ci.movie_id = ah.movie_id
    WHERE a.name IS NOT NULL AND ah.level < 5
),
MoviesWithRoles AS (
    SELECT
        t.title AS movie_title,
        t.production_year,
        ci.role_id,
        ct.kind AS role_name,
        STRING_AGG(DISTINCT a.actor_name, ', ') AS actors
    FROM aka_title t
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN role_type rt ON ci.role_id = rt.id
    JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE t.production_year BETWEEN 2000 AND 2023
    GROUP BY t.title, t.production_year, ci.role_id, ct.kind
),
FilteredMovies AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(actors) DESC) AS actor_rank
    FROM MoviesWithRoles
    GROUP BY movie_title, production_year, role_id, role_name
)
SELECT
    f.movie_title,
    f.production_year,
    f.role_name,
    f.actors,
    CASE 
        WHEN f.actor_rank <= 3 THEN f.actors || ' (Top 3)'
        ELSE f.actors
    END AS actor_summary
FROM FilteredMovies f
WHERE f.actor_rank <= 3
OR f.production_year IS NULL
ORDER BY f.production_year DESC, f.actor_rank;
