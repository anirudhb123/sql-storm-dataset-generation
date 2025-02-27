WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(CONCAT(a.name, ' as ', r.role), ', ') AS cast_details
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count,
        STRING_AGG(k.keyword, ', ') AS keywords
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
    COALESCE(mc.cast_count, 0) AS cast_count,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    COALESCE(mc.cast_details, 'No cast information') AS cast_details,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    (rm.production_year >= 2000 AND rm.production_year <= 2023)
    OR (rm.production_year IS NULL AND rm.title LIKE '%Mystery%')
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
