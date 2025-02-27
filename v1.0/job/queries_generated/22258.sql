WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS rank,
        STRING_AGG(ak.name, ', ') AS cast_names
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        at.title, at.production_year
),
MoviesWithInfo AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.rank,
        COALESCE(mi.info, 'No additional info') AS additional_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.cast_count > (SELECT AVG(cast_count) FROM RankedMovies)
        AND rm.production_year = mi.movie_id
)
SELECT
    mwi.movie_title,
    mwi.production_year,
    mwi.cast_count,
    mwi.additional_info,
    CASE 
        WHEN mwi.rank = 1 THEN 'Top movie of the year'
        WHEN mwi.cast_count IS NULL THEN 'No cast information available'
        ELSE 'Other movie'
    END AS classification,
    SUM(CASE WHEN mwi.additional_info LIKE '%Award%' THEN 1 ELSE 0 END) OVER (PARTITION BY mwi.production_year) AS award_count
FROM 
    MoviesWithInfo mwi
WHERE 
    mwi.cast_count IS NOT NULL
ORDER BY 
    mwi.production_year DESC, mwi.rank;

