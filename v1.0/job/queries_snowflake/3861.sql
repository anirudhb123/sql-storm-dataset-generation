WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(*) AS total_roles,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY COUNT(*) DESC) AS role_rank
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id, a.name
    HAVING COUNT(*) > 1
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    COALESCE(ta.actor_name, 'No Actors') AS actor_name,
    COALESCE(ta.total_roles, 0) AS role_count,
    CASE 
        WHEN rm.year_rank <= 5 THEN 'Top 5 Year'
        ELSE 'Other'
    END AS year_group
FROM RankedMovies rm
LEFT JOIN TopActors ta ON rm.movie_id = ta.movie_id AND ta.role_rank = 1
WHERE rm.production_year > 2000
ORDER BY rm.production_year DESC, role_count DESC;
