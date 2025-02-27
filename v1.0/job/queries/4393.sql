
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
MovieWithCast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(ci.person_id) AS cast_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
), 
FilteredMovies AS (
    SELECT 
        mwc.movie_id,
        mwc.title,
        mwc.production_year,
        mwc.cast_count
    FROM 
        MovieWithCast mwc
    WHERE 
        mwc.cast_count > 5
)

SELECT 
    fm.title,
    fm.production_year,
    COALESCE(k.keyword, 'No Keyword') AS movie_keyword,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_keyword mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, k.keyword
HAVING 
    COUNT(DISTINCT cn.id) > 0
ORDER BY 
    fm.production_year DESC, fm.title
LIMIT 100;
