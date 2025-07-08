
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC, mt.title) AS rank
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),

MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        c.movie_id
),

MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(mi.info, 'No information available') AS info
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
)

SELECT 
    rm.title,
    rm.production_year,
    mc.total_cast,
    mc.cast_names,
    mi.info
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
FULL OUTER JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank = 1
  AND 
    (mc.total_cast > 5 OR mi.info IS NOT NULL)
ORDER BY 
    rm.production_year DESC,
    rm.title ASC;
