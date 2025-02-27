WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
CastDetails AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS total_cast, 
        MIN(a.name) AS lead_actor
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(mi.info, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id, 
    rm.title, 
    rm.production_year, 
    cd.total_cast, 
    cd.lead_actor, 
    mi.keywords,
    CASE 
        WHEN cd.total_cast > 5 THEN 'Large Cast'
        WHEN cd.total_cast BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    COALESCE(mi.keywords, 'No Keywords') AS keyword_info
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.year_rank <= 10
ORDER BY 
    rm.production_year DESC, 
    cd.total_cast DESC;
