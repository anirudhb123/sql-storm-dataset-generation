WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS all_actors
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id, 
    rm.title, 
    rm.production_year, 
    rm.total_cast, 
    rm.all_actors, 
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC;
