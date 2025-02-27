WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS main_cast
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
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
),
CombinedInfo AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.cast_count, 
        rm.main_cast,
        mk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
)
SELECT 
    movie_id, 
    title, 
    production_year, 
    cast_count,
    main_cast,
    keywords
FROM 
    CombinedInfo
WHERE 
    cast_count > 10
ORDER BY 
    production_year DESC, 
    cast_count DESC
LIMIT 10;
