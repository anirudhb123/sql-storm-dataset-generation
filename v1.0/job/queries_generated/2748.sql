WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS rank_per_year
    FROM title m
    WHERE m.production_year IS NOT NULL
),
CountCastPerMovie AS (
    SELECT 
        c.movie_id, 
        COUNT(c.person_id) AS cast_count
    FROM cast_info c
    GROUP BY c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_kinds
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cc.cast_count, 0) AS number_of_cast,
    cd.company_names,
    cd.company_kinds
FROM RankedMovies rm
LEFT JOIN CountCastPerMovie cc ON rm.movie_id = cc.movie_id
LEFT JOIN CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE rm.rank_per_year <= 5
ORDER BY rm.production_year DESC, rm.movie_id;
