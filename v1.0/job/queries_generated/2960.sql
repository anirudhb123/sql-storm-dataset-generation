WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_in_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
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
)
SELECT 
    rm.movie_id,
    rm.title,
    COALESCE(rd.total_cast, 0) AS total_cast,
    COALESCE(rd.cast_names, 'No Cast Available') AS cast_details,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN rm.production_year > 2000 THEN 'Modern'
        ELSE 'Classic'
    END AS movie_type
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails rd ON rm.movie_id = rd.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank_in_year <= 5
ORDER BY 
    rm.production_year DESC, rm.movie_id;
