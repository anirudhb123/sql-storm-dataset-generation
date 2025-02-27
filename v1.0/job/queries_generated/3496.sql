WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT ki.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT mt.info, '; ') AS movie_notes
    FROM 
        movie_keyword mk
    JOIN 
        keyword ki ON mk.keyword_id = ki.id
    JOIN 
        movie_info m ON mk.movie_id = m.movie_id
    JOIN 
        info_type mt ON m.info_type_id = mt.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    mi.keywords,
    mi.movie_notes
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieInfo mi ON mi.movie_id IN (
        SELECT 
            mk.movie_id
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        WHERE 
            k.keyword LIKE ANY (ARRAY['%action%', '%thriller%'])
    )
WHERE 
    rm.rn <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
