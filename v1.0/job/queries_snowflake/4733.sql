
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rn
    FROM title m
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        AVG(CASE WHEN c.country_code IS NULL THEN 0 ELSE 1 END) AS valid_country_ratio
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    GROUP BY mc.movie_id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        LISTAGG(DISTINCT cr.role, ', ') AS roles
    FROM cast_info ci
    JOIN role_type cr ON ci.role_id = cr.id
    GROUP BY ci.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(cc.company_count, 0) AS total_companies,
    COALESCE(cc.valid_country_ratio, 0) AS country_valid_ratio,
    cr.roles,
    CASE
        WHEN cc.company_count > 5 THEN 'Highly Produced'
        WHEN cc.company_count BETWEEN 3 AND 5 THEN 'Moderately Produced'
        ELSE 'Low Production'
    END AS production_level
FROM RankedMovies rm
LEFT JOIN CompanyCounts cc ON rm.movie_id = cc.movie_id
LEFT JOIN CastRoles cr ON rm.movie_id = cr.movie_id
WHERE rm.rn <= 10 AND (cc.company_count IS NOT NULL OR cr.roles IS NOT NULL)
ORDER BY rm.production_year DESC, rm.movie_id
LIMIT 20 OFFSET 0;
