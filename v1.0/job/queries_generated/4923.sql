WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT kt.keyword, ', ') AS genres
    FROM 
        movie_keyword mt 
    JOIN 
        keyword kt ON mt.keyword_id = kt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast,
    COALESCE(mg.genres, 'No genres') AS genres
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieGenres mg ON rm.movie_id = mg.movie_id
WHERE 
    rm.rank <= 5 
    AND rm.production_year IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast DESC;

WITH MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    t.title,
    t.production_year,
    STRING_AGG(DISTINCT ci.company_name || ' (' || ci.company_type || ')', ', ') AS companies
FROM 
    aka_title t
LEFT JOIN 
    MovieCompanyInfo ci ON t.id = ci.movie_id
GROUP BY 
    t.id, t.title, t.production_year
HAVING 
    COUNT(DISTINCT ci.company_name) > 0
ORDER BY 
    t.production_year DESC;
