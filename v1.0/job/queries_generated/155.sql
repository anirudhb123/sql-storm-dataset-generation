WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
PopularCast AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS cast_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role IN ('Lead', 'Supporting')
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(i.info, '; ') AS movie_info
    FROM 
        movie_info m
    JOIN 
        info_type i ON m.info_type_id = i.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(pc.cast_count, 0) AS total_cast,
    mi.movie_info
FROM 
    RankedMovies rm
LEFT JOIN 
    PopularCast pc ON rm.movie_id = pc.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC, rm.title;
