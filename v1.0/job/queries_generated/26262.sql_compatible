
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS cast_names
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year, rm.cast_count, rm.cast_names
),
MoviesWithCompany AS (
    SELECT 
        mwk.movie_id,
        mwk.movie_title,
        mwk.production_year,
        mwk.cast_count,
        mwk.cast_names,
        mwk.keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        MoviesWithKeywords mwk
    LEFT JOIN 
        movie_companies mc ON mwk.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mwk.movie_id, mwk.movie_title, mwk.production_year, mwk.cast_count, mwk.cast_names, mwk.keywords
)
SELECT 
    mwc.movie_id,
    mwc.movie_title,
    mwc.production_year,
    mwc.cast_count,
    mwc.cast_names,
    mwc.keywords,
    mwc.companies
FROM 
    MoviesWithCompany mwc
ORDER BY 
    mwc.production_year DESC,
    mwc.cast_count DESC;
