WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title AS mt
    LEFT JOIN 
        complete_cast AS cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
MovieKeywords AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        aka_title AS mt
    LEFT JOIN 
        movie_keyword AS mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN COUNT(DISTINCT mco.company_id) > 0 THEN 'Yes'
        ELSE 'No'
    END AS has_production_company
FROM 
    TopMovies AS tm
LEFT JOIN 
    movie_companies AS mco ON tm.movie_id = mco.movie_id
LEFT JOIN 
    MovieKeywords AS mk ON tm.movie_id = mk.movie_id
GROUP BY 
    tm.title, tm.production_year, tm.cast_count, mk.keywords
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
