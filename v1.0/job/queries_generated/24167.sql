WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_within_year <= 5
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
MovieCompanyInfo AS (
    SELECT 
        m.id AS movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        m.production_year
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.title,
    tm.production_year,
    mk.keyword_list,
    mc.company_name,
    mc.company_type
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.movie_id
LEFT JOIN 
    MovieCompanyInfo mc ON tm.title = mc.movie_id
WHERE 
    mc.company_type IS NOT NULL OR mk.keyword_list IS NOT NULL
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC;
    
-- Additional filtering/logic for Bizarre edge cases or NULL handling
WITH NULL_Cases AS (
    SELECT 
        t.title,
        COUNT(DISTINCT mc.id) AS unique_company_count,
        COUNT(DISTINCT k.id) AS unique_keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title
    HAVING 
        (COUNT(DISTINCT mc.id) = 0 AND COUNT(DISTINCT k.id) = 0) 
        OR (COUNT(DISTINCT mc.id) > 1 AND COUNT(DISTINCT k.id) < 2)
)
SELECT 
    n.title,
    n.unique_company_count,
    n.unique_keyword_count
FROM 
    NULL_Cases n
WHERE 
    n.unique_company_count IS NULL 
    OR n.unique_keyword_count = 0;

