WITH RankedTitles AS (
    SELECT 
        a.title,
        t.production_year,
        Dense_Rank() OVER (PARTITION BY t.production_year ORDER BY a.title) as title_rank,
        COUNT(DISTINCT m.company_id) OVER (PARTITION BY t.id) as company_count
    FROM aka_title a 
    JOIN title t ON a.movie_id = t.id
    LEFT JOIN movie_companies m ON t.id = m.movie_id
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) as actor_count,
        STRING_AGG(DISTINCT CONCAT(n.name, ' (', r.role, ')'), ', ') AS actor_roles
    FROM cast_info c 
    JOIN role_type r ON c.role_id = r.id
    JOIN aka_name n ON n.person_id = c.person_id
    GROUP BY c.movie_id
),
FilteredMovies AS (
    SELECT 
        rt.title,
        rt.production_year,
        ar.actor_count,
        ar.actor_roles,
        CASE WHEN ar.actor_count IS NULL THEN 'No Actors' ELSE 'Has Actors' END as actor_status
    FROM RankedTitles rt
    LEFT JOIN ActorRoles ar ON rt.title = rt.title
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_count,
    fm.actor_roles,
    fm.actor_status
FROM FilteredMovies fm
WHERE fm.production_year >= 2000 AND fm.actor_count IS NOT NULL
ORDER BY fm.production_year DESC, fm.actor_count DESC
LIMIT 100;
