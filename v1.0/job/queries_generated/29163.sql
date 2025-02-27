WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM aka_title at
    WHERE at.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT an.name, ', ') AS cast_names,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM complete_cast mc
    JOIN cast_info ci ON mc.movie_id = ci.movie_id
    JOIN aka_name an ON ci.person_id = an.person_id
    GROUP BY mc.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT it.info, '; ') AS movie_infos
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
),
FinalBenchmark AS (
    SELECT 
        rm.title,
        rm.production_year,
        mc.cast_names,
        mc.total_cast,
        mi.movie_infos
    FROM RankedMovies rm
    LEFT JOIN MovieCast mc ON rm.movie_id = mc.movie_id
    LEFT JOIN MovieInfo mi ON rm.movie_id = mi.movie_id
    WHERE rm.title_rank <= 10
    ORDER BY rm.production_year, rm.title
)
SELECT 
    title,
    production_year,
    cast_names,
    total_cast,
    movie_infos
FROM FinalBenchmark;
