WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS movie_rank,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        rm.cast_count > 2  
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.cast_count
),
MovieCompany AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.name) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mw.title,
    mw.production_year,
    mw.cast_count,
    mw.keywords,
    COALESCE(mco.company_count, 0) AS company_count,
    mco.companies,
    COUNT(*) FILTER (WHERE mw.production_year IS NOT NULL) AS valid_movie_count,
    CASE
        WHEN mw.production_year IS NULL THEN 'YEAR UNKNOWN'
        WHEN mw.production_year < 2000 THEN 'OLD MOVIE'
        ELSE 'RECENT MOVIE'
    END AS movie_category
FROM 
    MoviesWithKeywords mw
LEFT JOIN 
    MovieCompany mco ON mw.movie_id = mco.movie_id
GROUP BY 
    mw.movie_id, mw.title, mw.production_year, mw.cast_count, mw.keywords, mco.company_count, mco.companies
ORDER BY 
    movie_category, mw.production_year DESC
LIMIT 1000;