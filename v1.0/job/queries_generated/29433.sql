WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        STRING_AGG(DISTINCT akn.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        complete_cast cct ON mt.id = cct.movie_id
    JOIN 
        cast_info cc ON cct.subject_id = cc.person_id
    LEFT JOIN 
        aka_name akn ON cc.person_id = akn.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        ROW_NUMBER() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > 0
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.cast_names
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.cast_count DESC;
