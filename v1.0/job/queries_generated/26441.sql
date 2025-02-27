WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT cc.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id
    HAVING 
        COUNT(DISTINCT cc.person_id) > 5
), 


MoviesWithKeywords AS (
    SELECT 
        rm.title, 
        rm.production_year,
        rm.cast_count,
        rm.actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id IN (SELECT id FROM title WHERE title = rm.title AND production_year = rm.production_year)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.title, rm.production_year, rm.cast_count, rm.actors
),

FinalOutput AS (
    SELECT 
        mwk.title,
        mwk.production_year,
        mwk.cast_count,
        mwk.actors,
        mwk.keywords
    FROM 
        MoviesWithKeywords mwk
    WHERE 
        mwk.production_year >= 2000
    ORDER BY 
        mwk.cast_count DESC
    LIMIT 10
)

SELECT 
    *
FROM 
    FinalOutput;
