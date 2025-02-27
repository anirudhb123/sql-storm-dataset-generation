WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
),
DetailedCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        SUM(CASE WHEN ak.name IS NULL THEN 1 ELSE 0 END) AS null_names_count
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        ARRAY_AGG(DISTINCT it.info) AS info_details
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    dc.total_cast,
    dc.cast_names,
    dc.null_names_count,
    mi.info_details
FROM 
    RankedMovies rm
LEFT JOIN 
    DetailedCast dc ON rm.movie_id = dc.movie_id
FULL OUTER JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, dc.total_cast DESC NULLS LAST;
