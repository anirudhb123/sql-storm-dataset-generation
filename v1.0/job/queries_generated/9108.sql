WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.cast_count
),
TopMovies AS (
    SELECT 
        mwk.title,
        mwk.production_year,
        mwk.cast_count,
        mwk.keywords,
        ROW_NUMBER() OVER (ORDER BY mwk.cast_count DESC) AS rank
    FROM 
        MoviesWithKeywords mwk
    WHERE 
        mwk.production_year >= 2000
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.keywords
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
