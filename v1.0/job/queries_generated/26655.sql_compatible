
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 2
),
MovieGenres AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT kt.kind, ',') AS genres
    FROM 
        aka_title m
    JOIN 
        kind_type kt ON m.kind_id = kt.id
    GROUP BY 
        m.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ',') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    mg.genres,
    mk.keywords
FROM 
    RankedMovies rm
JOIN 
    MovieGenres mg ON rm.movie_id = mg.movie_id
JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.production_year > 2000
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC
LIMIT 10;
