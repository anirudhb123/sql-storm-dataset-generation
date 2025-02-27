WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
), MovieKeywords AS (
    SELECT 
        t.id AS movie_id,
        k.keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
), FinalOutput AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.title = mk.movie_id
    GROUP BY 
        rm.title, rm.production_year, rm.cast_count
)
SELECT 
    *,
    RANK() OVER (ORDER BY cast_count DESC) AS rank
FROM 
    FinalOutput
ORDER BY 
    rank;
