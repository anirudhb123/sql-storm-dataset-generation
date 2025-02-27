WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(m.prod_year, 'Unknown') AS production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        MAX(mi.info) AS info
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id, m.title, m.prod_year
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    md.keywords,
    COALESCE(md.info, 'No additional info') AS additional_info
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieDetails md ON rm.movie_title = md.title 
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
