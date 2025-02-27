WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
), 
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_infos
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    r.title,
    r.production_year,
    r.cast_count,
    COALESCE(mi.movie_infos, 'No Info') AS movie_infos
FROM 
    RankedMovies r
LEFT JOIN 
    MovieInfo mi ON r.movie_id = mi.movie_id
WHERE 
    r.rank <= 5
ORDER BY 
    r.production_year DESC, 
    r.cast_count DESC;
