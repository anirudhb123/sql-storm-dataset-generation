WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS movie_rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
MoviesWithCastCount AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(cast_count.cast_member_count, 0) AS cast_member_count
    FROM 
        MoviesWithKeywords m
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(DISTINCT person_id) AS cast_member_count
        FROM 
            cast_info
        GROUP BY 
            movie_id
    ) cast_count ON m.movie_id = cast_count.movie_id
)
SELECT 
    mwk.movie_id,
    mwk.title,
    mwk.production_year,
    mwk.keywords,
    mwc.cast_member_count
FROM 
    MoviesWithCastCount mwc
JOIN 
    MoviesWithKeywords mwk ON mwc.movie_id = mwk.movie_id
WHERE 
    mwc.cast_member_count > (
        SELECT AVG(cast_count) 
        FROM (
            SELECT COUNT(DISTINCT person_id) AS cast_count
            FROM cast_info
            GROUP BY movie_id
        ) AS avg_cast
    )
  AND mwk.production_year BETWEEN 2000 AND 2020
ORDER BY 
    mwk.production_year DESC, 
    mwc.cast_member_count DESC
LIMIT 10;
