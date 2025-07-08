
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS year_rank
    FROM aka_title mt
    WHERE mt.kind_id IN (
        SELECT id FROM kind_type WHERE kind IN ('movie', 'feature')
    )
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        LISTAGG(DISTINCT an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS cast_names
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    GROUP BY ci.movie_id
),
MovieCompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.total_cast, 0) AS total_cast,
    COALESCE(cd.cast_names, 'No Cast') AS cast_names,
    COALESCE(mcc.total_companies, 0) AS total_companies
FROM RankedMovies rm
LEFT JOIN CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN MovieCompanyCounts mcc ON rm.movie_id = mcc.movie_id
WHERE rm.year_rank <= 5 
ORDER BY rm.production_year DESC, rm.title;
