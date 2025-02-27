WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM aka_title at
    WHERE at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
), MovieDetail AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(cc.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM RankedMovies rm
    LEFT JOIN cast_info cc ON rm.movie_id = cc.movie_id
    LEFT JOIN aka_name ak ON cc.person_id = ak.person_id
    GROUP BY rm.movie_id, rm.title, rm.production_year
), MovieInfo AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        MIN(mi.info) AS first_info
    FROM MovieDetail md
    LEFT JOIN movie_info mi ON md.movie_id = mi.movie_id
    GROUP BY md.movie_id, md.title, md.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.actor_names,
    mi.first_info
FROM MovieDetail md
INNER JOIN MovieInfo mi ON md.movie_id = mi.movie_id
WHERE md.cast_count > 5
  AND (mi.first_info IS NULL OR mi.first_info NOT LIKE '%unreleased%')
ORDER BY md.production_year DESC, md.cast_count DESC
LIMIT 50;
