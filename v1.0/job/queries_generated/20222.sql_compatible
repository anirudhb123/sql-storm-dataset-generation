
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5  
),

CompanyMovieInfo AS (
    SELECT 
        mm.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_info,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_companies mm
    JOIN 
        company_name cn ON mm.company_id = cn.id
    JOIN 
        movie_info mi ON mm.movie_id = mi.movie_id
    JOIN 
        movie_keyword mk ON mm.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mm.movie_id
)

SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    cmi.companies,
    cmi.movie_info,
    cmi.keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    CompanyMovieInfo cmi ON fm.movie_id = cmi.movie_id
ORDER BY 
    fm.production_year, fm.cast_count DESC;
