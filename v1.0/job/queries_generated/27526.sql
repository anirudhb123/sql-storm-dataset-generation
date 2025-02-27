WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithCompanies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        rm.keyword_count,
        rm.keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.cast_count, rm.cast_names, rm.keyword_count, rm.keywords
)
SELECT 
    mwc.movie_id,
    mwc.title,
    mwc.production_year,
    mwc.cast_count,
    mwc.cast_names,
    mwc.keyword_count,
    mwc.keywords,
    mwc.company_count
FROM 
    MoviesWithCompanies mwc
WHERE 
    mwc.production_year >= 2000
ORDER BY 
    mwc.cast_count DESC, mwc.production_year ASC
LIMIT 10;
