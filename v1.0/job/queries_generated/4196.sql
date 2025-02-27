WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
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
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cd.total_cast,
    cd.cast_names,
    COALESCE(mi.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN cd.total_cast > 10 THEN 'Large Cast'
        WHEN cd.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank_per_year <= 5
ORDER BY 
    rm.production_year DESC, 
    cd.total_cast DESC;
