WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = m.id AND mi.info_type_id = 1) AS info_count
    FROM title m
    WHERE m.production_year >= 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = m.id AND mi.info_type_id = 1) AS info_count
    FROM title m
    JOIN MovieHierarchy mh ON m.id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.info_count DESC) AS rank
    FROM MovieHierarchy mh
    WHERE mh.info_count > 0
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        cr.role AS role_name,
        COUNT(ci.person_id) AS role_count
    FROM cast_info ci
    JOIN role_type cr ON ci.role_id = cr.id
    GROUP BY ci.movie_id, cr.role
),
HighestRoleCounts AS (
    SELECT 
        movie_id,
        role_name,
        role_count,
        RANK() OVER (PARTITION BY movie_id ORDER BY role_count DESC) AS role_rank
    FROM CastRoles
)
SELECT 
    tm.title,
    tm.production_year,
    cc.company_count,
    COALESCE(hr.role_name, 'No Roles') AS top_role,
    COALESCE(hr.role_count, 0) AS top_role_count
FROM TopMovies tm
LEFT JOIN CompanyCounts cc ON tm.movie_id = cc.movie_id
LEFT JOIN HighestRoleCounts hr ON tm.movie_id = hr.movie_id AND hr.role_rank = 1
WHERE tm.rank <= 10
ORDER BY tm.production_year DESC, cc.company_count DESC;
