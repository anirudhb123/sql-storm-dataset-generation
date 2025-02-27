WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        RANK() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank,
        COUNT(ci.id) AS cast_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
), MovieKeywords AS (
    SELECT 
        at.id AS movie_id,
        mk.keyword
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    WHERE 
        mk.keyword IN ('Action', 'Drama')
), FeaturedMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        COUNT(mk.keyword) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.title = mk.title
    GROUP BY 
        rm.title, rm.production_year, rm.cast_count
    HAVING 
        COUNT(mk.keyword) > 0
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.keyword_count,
    CASE 
        WHEN fm.cast_count IS NULL THEN 'Unknown'
        WHEN fm.cast_count >= 10 THEN 'Popular'
        ELSE 'Niche'
    END AS movie_type
FROM 
    FeaturedMovies fm
ORDER BY 
    fm.production_year DESC, fm.cast_count DESC
FETCH FIRST 10 ROWS ONLY;
