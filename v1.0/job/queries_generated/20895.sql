WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS year_rank,
        COUNT(c.id) OVER (PARTITION BY m.id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year IS NOT NULL AND 
        m.production_year BETWEEN 2000 AND 2023
),
DirectorCast AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS director_count
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        movie_title mt ON mc.movie_id = mt.id
    JOIN 
        cast_info c ON mc.movie_id = c.movie_id
    WHERE 
        ct.kind = 'Director'
    GROUP BY 
        m.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        AVG(m_info.info_length) AS avg_info_length
    FROM 
        aka_title m
    JOIN (
        SELECT 
            movie_id, 
            LENGTH(info) AS info_length 
        FROM 
            movie_info
    ) m_info ON m.id = m_info.movie_id
    GROUP BY 
        m.id
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        RM.cast_count,
        COALESCE(dc.director_count, 0) AS director_count,
        mi.avg_info_length
    FROM 
        RankedMovies rm
    LEFT JOIN 
        DirectorCast dc ON rm.movie_id = dc.movie_id
    LEFT JOIN 
        MovieInfo mi ON rm.movie_id = mi.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    director_count,
    avg_info_length
FROM 
    FinalResults
WHERE 
    (cast_count > 5 OR (director_count = 0 AND avg_info_length IS NULL))
AND 
    (production_year >= 2010 OR (production_year < 2015 AND title ILIKE '%action%'))
ORDER BY 
    production_year DESC,
    title ASC
LIMIT 50
OFFSET 10;

