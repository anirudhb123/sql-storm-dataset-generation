WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_in_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
HighestRankedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ci.role_id
    FROM 
        RankedMovies rm
    JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    WHERE 
        rm.rank_in_year = 1
),
MoviesWithKeywords AS (
    SELECT 
        h.movie_id,
        h.title,
        k.keyword
    FROM 
        HighestRankedMovies h
    LEFT JOIN 
        movie_keyword mk ON h.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    mwk.title AS Movie_Title,
    mwk.production_year AS Release_Year,
    STRING_AGG(DISTINCT mwk.keyword, ', ') AS Keywords,
    COALESCE(cn.name, 'Unknown') AS Company_Name,
    COUNT(ci.person_id) AS Cast_Count
FROM 
    MoviesWithKeywords mwk
LEFT JOIN 
    movie_companies mc ON mwk.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    complete_cast cc ON mwk.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
GROUP BY 
    mwk.movie_id, mwk.title, mwk.production_year, cn.name
HAVING 
    COUNT(ci.person_id) > 0
ORDER BY 
    mwk.production_year DESC, mwk.title;
