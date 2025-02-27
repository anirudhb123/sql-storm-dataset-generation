WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        a.production_year >= 2000
        AND ak.name IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.total_cast,
        rm.cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    JOIN 
        movie_keyword mk ON rm.movie_title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_title, rm.production_year, rm.total_cast, rm.cast_names
),
TopMovies AS (
    SELECT 
        mwk.movie_title,
        mwk.production_year,
        mwk.total_cast,
        mwk.cast_names,
        mwk.keywords,
        ROW_NUMBER() OVER (ORDER BY mwk.total_cast DESC) AS rn
    FROM 
        MoviesWithKeywords mwk
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.cast_names,
    tm.keywords
FROM 
    TopMovies tm
WHERE 
    tm.rn <= 10
ORDER BY 
    tm.total_cast DESC;
