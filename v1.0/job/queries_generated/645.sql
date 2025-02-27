WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(*) OVER (PARTITION BY t.kind_id) AS kind_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
),
MovieWithCast AS (
    SELECT 
        rm.title,
        rm.production_year,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.title = cc.subject_id
    LEFT JOIN 
        cast_info ci ON cc.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        rm.title, rm.production_year
),
FilteredMovies AS (
    SELECT 
        mwc.title,
        mwc.production_year,
        mwc.cast_count,
        mwc.actor_names
    FROM 
        MovieWithCast mwc
    WHERE 
        mwc.cast_count > 3
        AND mwc.production_year BETWEEN 2000 AND 2020
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    COALESCE(fm.actor_names, 'No Actors') AS actor_names,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id IN (SELECT mc.movie_id FROM complete_cast mc WHERE mc.subject_id = fm.title)) AS keyword_count
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
