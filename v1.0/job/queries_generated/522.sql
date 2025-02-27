WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.name AS actor_name,
        c.movie_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY c.nr_order) AS role_rank
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN role_type r ON c.role_id = r.id
),
MovieCompanies AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM movie_companies m
    JOIN company_name co ON m.company_id = co.id
    GROUP BY m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ar.actor_name,
    ar.role,
    mc.num_companies,
    mc.company_names,
    CASE 
        WHEN mc.num_companies IS NULL THEN 'No Companies'
        ELSE 'Companies Exist'
    END AS company_status,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = rm.movie_id AND mi.info_type_id = 1) AS info_count
FROM RankedMovies rm
LEFT JOIN ActorRoles ar ON rm.movie_id = ar.movie_id AND ar.role_rank = 1
LEFT JOIN MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE rm.year_rank <= 5
ORDER BY rm.production_year DESC, rm.movie_id;
