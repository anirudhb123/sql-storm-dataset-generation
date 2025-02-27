WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_in_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
MovieKeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
MoviesWithDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.total_cast,
        cd.cast_names,
        COALESCE(mkc.keyword_count, 0) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        MovieKeywordCount mkc ON rm.movie_id = mkc.movie_id
    WHERE 
        rm.rank_in_year <= 5 
)

SELECT 
    m.title,
    m.production_year,
    m.total_cast,
    m.cast_names,
    m.keyword_count,
    CASE 
        WHEN m.keyword_count > 10 THEN 'Popular'
        WHEN m.keyword_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Less Popular'
    END AS popularity
FROM 
    MoviesWithDetails m
ORDER BY 
    m.production_year DESC, m.total_cast DESC;