WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT cc.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(cc.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast mc ON mc.movie_id = mt.id
    LEFT JOIN 
        cast_info cc ON cc.movie_id = mt.id
    GROUP BY 
        mt.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        mk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON mk.movie_id = rm.movie_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.keywords, 'No Keywords') AS keywords,
    COALESCE(NULLIF(tm.total_cast, 0), 'No Cast') AS total_cast
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC;
