WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS movie_rank
    FROM 
        aka_title at 
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieCast AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT cc.person_id) AS total_cast
    FROM 
        cast_info cc
    GROUP BY 
        cc.movie_id
),
TitleInfo AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT mt.info, ', ') AS merged_info
    FROM 
        movie_info mt
    WHERE 
        mt.info_type_id IN (SELECT id FROM info_type WHERE info = 'summary')
    GROUP BY 
        mt.movie_id
),
MoviesWithCast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mc.total_cast, 0) AS cast_count,
        ti.merged_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCast mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        TitleInfo ti ON rm.movie_id = ti.movie_id
)
SELECT 
    mwc.movie_id,
    mwc.title,
    mwc.production_year,
    mwc.cast_count,
    mwc.merged_info,
    CASE 
        WHEN mwc.cast_count > 10 THEN 'Blockbuster'
        WHEN mwc.cast_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Low-budget'
    END AS budget_category
FROM 
    MoviesWithCast mwc
WHERE 
    mwc.production_year BETWEEN 2000 AND 2020
    AND mwc.cast_count IS NOT NULL
UNION 
SELECT 
    mt.movie_id,
    mt.title,
    mt.production_year,
    0 AS cast_count,  
    'No summary available' AS merged_info,
    'Unknown' AS budget_category
FROM 
    aka_title mt
WHERE 
    mt.production_year NOT IN (SELECT DISTINCT production_year FROM RankedMovies) 
    AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
ORDER BY 
    production_year DESC, title;
