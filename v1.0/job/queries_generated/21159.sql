WITH RECURSIVE RoleHierarchy AS (
    SELECT c.movie_id, c.person_id, r.role 
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    WHERE r.role IS NOT NULL AND r.role NOT LIKE '%extra%'
    
    UNION ALL

    SELECT c.movie_id, c.person_id, r.role
    FROM cast_info c
    JOIN RoleHierarchy rh ON c.movie_id = rh.movie_id
    JOIN role_type r ON c.role_id = r.id
    WHERE r.role IS NOT NULL AND r.role NOT LIKE '%extra%'
),

TopMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT c.person_id) AS num_actors,
        AVG(y.production_year) AS avg_production_year
    FROM 
        aka_title t
    LEFT JOIN cast_info c ON c.movie_id = t.movie_id
    LEFT JOIN title y ON t.id = y.id
    GROUP BY t.id, t.title
    HAVING COUNT(DISTINCT c.person_id) > 5
),

MovieCompanies AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names,
        COUNT(DISTINCT mc.company_type_id) AS unique_company_types
    FROM 
        movie_companies m
    JOIN company_name cn ON m.company_id = cn.id
    JOIN company_type ct ON m.company_type_id = ct.id
    GROUP BY m.movie_id
)

SELECT
    tm.title,
    tm.num_actors,
    ROUND(tm.avg_production_year, 2) AS avg_year,
    COALESCE(mc.company_names, 'No companies') AS companies,
    COALESCE(mc.unique_company_types, 0) AS company_type_count,
    RANK() OVER (ORDER BY tm.num_actors DESC) AS actor_rank
FROM 
    TopMovies tm
LEFT JOIN MovieCompanies mc ON tm.movie_id = mc.movie_id
WHERE 
    (tm.num_actors >= 10 OR mc.unique_company_types > 1)
    AND EXISTS (
        SELECT 1 
        FROM aka_name an 
        WHERE an.person_id IN (
            SELECT rh.person_id 
            FROM RoleHierarchy rh 
            WHERE rh.movie_id = tm.movie_id
        ) 
        AND an.name LIKE '%John%'
    )
ORDER BY 
    actor_rank,
    tm.title ASC;

