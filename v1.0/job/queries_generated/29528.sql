WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT cm.company_id) AS production_company_count,
        AVG(CASE WHEN EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = m.id AND mi.info_type_id = it.id) 
                 THEN 1 ELSE 0 END) AS avg_info_per_movie,
        RANK() OVER (ORDER BY COUNT(DISTINCT cm.company_id) DESC) AS rank_by_company
    FROM 
        title m
    LEFT JOIN movie_companies cm ON m.id = cm.movie_id
    LEFT JOIN company_type ct ON cm.company_type_id = ct.id
    LEFT JOIN info_type it ON 1=1
    GROUP BY 
        m.id
    HAVING 
        COUNT(DISTINCT cm.company_id) > 1
),
AkaNameCount AS (
    SELECT 
        ak.person_id,
        COUNT(ak.id) AS aka_count
    FROM 
        aka_name ak
    GROUP BY 
        ak.person_id
),
CastRoles AS (
    SELECT 
        ci.person_id,
        rt.role AS role_name,
        COUNT(ci.id) AS role_count,
        SUM(CASE WHEN rt.role LIKE 'Actor%' THEN 1 ELSE 0 END) AS actor_roles
    FROM 
        cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id, rt.role
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rmc.production_company_count,
    rmc.avg_info_per_movie,
    rmc.rank_by_company,
    an.aka_count,
    cr.role_name,
    cr.role_count,
    cr.actor_roles
FROM 
    RankedMovies rm
JOIN AkaNameCount an ON an.person_id IN (SELECT DISTINCT ci.person_id FROM cast_info ci WHERE ci.movie_id = rm.movie_id)
JOIN CastRoles cr ON cr.person_id IN (SELECT DISTINCT ci.person_id FROM cast_info ci WHERE ci.movie_id = rm.movie_id)
ORDER BY 
    rm.rank_by_company, an.aka_count DESC, cr.role_count DESC;

