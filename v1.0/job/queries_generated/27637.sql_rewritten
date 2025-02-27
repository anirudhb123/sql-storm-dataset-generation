WITH RankedMovies AS (
    SELECT 
        mv.id AS movie_id,
        mv.title,
        mv.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS all_aka_names,
        ROW_NUMBER() OVER (PARTITION BY mv.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        title mv
    JOIN 
        movie_companies mc ON mv.id = mc.movie_id
    JOIN 
        cast_info ca ON mv.id = ca.movie_id
    LEFT JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    GROUP BY 
        mv.id, mv.title, mv.production_year
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.all_aka_names
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 10 
ORDER BY 
    rm.production_year, rm.cast_count DESC;