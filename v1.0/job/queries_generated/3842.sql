WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
), 
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        cast_count 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
), 
KeywordStats AS (
    SELECT 
        mt.movie_id, 
        k.keyword, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.movie_id, k.keyword
), 
MovieWithKeywords AS (
    SELECT 
        tm.title, 
        tm.production_year, 
        k.keyword, 
        k.keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        KeywordStats k ON tm.production_year = k.movie_id
), 
CompanyInfo AS (
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
    WHERE 
        ct.kind IS NOT NULL
)
SELECT 
    mwk.title, 
    mwk.production_year, 
    mwk.keyword, 
    COUNT(*) FILTER (WHERE ci.person_role_id IS NOT NULL) AS registered_roles,
    c.company_name,
    c.company_type
FROM 
    MovieWithKeywords mwk
LEFT JOIN 
    complete_cast cc ON mwk.title = (SELECT title FROM aka_title WHERE id = cc.movie_id LIMIT 1)
LEFT JOIN 
    CompanyInfo c ON mwk.title = (SELECT title FROM aka_title WHERE id = c.movie_id LIMIT 1)
LEFT JOIN 
    cast_info ci ON mwk.title = (SELECT title FROM aka_title WHERE id = ci.movie_id LIMIT 1)
GROUP BY 
    mwk.title, mwk.production_year, mwk.keyword, c.company_name, c.company_type
ORDER BY 
    mwk.production_year DESC, registered_roles DESC;
