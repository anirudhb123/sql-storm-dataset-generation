
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CastInfo AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    COALESCE(rm.production_year, 0) AS production_year,
    mk.keywords,
    COALESCE(ci.total_cast, 0) AS cast_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    CastInfo ci ON rm.movie_id = ci.movie_id
WHERE 
    (rm.rank <= 5 OR mk.keywords IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title
LIMIT 10;
