WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank
    FROM title m
    WHERE m.production_year >= 2000
),
MovieWithCompanies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM RankedMovies rm
    LEFT JOIN movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY rm.movie_id, rm.title, rm.production_year
),
CastAndRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', rt.role, ')'), ', ') AS cast_info
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type rt ON c.role_id = rt.id
    GROUP BY c.movie_id
)
SELECT 
    mwc.movie_id,
    mwc.title,
    mwc.production_year,
    mwc.company_names,
    COALESCE(ca.cast_count, 0) AS total_cast,
    COALESCE(ca.cast_info, 'None') AS cast_details
FROM MovieWithCompanies mwc
LEFT JOIN CastAndRoles ca ON mwc.movie_id = ca.movie_id
WHERE mwc.company_names IS NOT NULL
ORDER BY mwc.production_year DESC, mwc.title;
