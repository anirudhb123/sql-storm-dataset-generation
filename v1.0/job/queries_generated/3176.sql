WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(cc.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(cc.person_id) DESC) as rn
    FROM 
        aka_title a
        JOIN complete_cast cc ON a.id = cc.movie_id
    WHERE 
        a.production_year IS NOT NULL 
    GROUP BY 
        a.title, a.production_year
), 
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rn <= 10
), 
KeywordCount AS (
    SELECT 
        m.title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        TopMovies m
        LEFT JOIN movie_keyword mk ON m.title = (SELECT title FROM aka_title WHERE id = mk.movie_id) 
    GROUP BY 
        m.title
), 
CompanyInfo AS (
    SELECT 
        a.title,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        topMovies a
        LEFT JOIN movie_companies mc ON a.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
        LEFT JOIN company_name c ON mc.company_id = c.id
        LEFT JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    k.title,
    k.keyword_count,
    ci.company_name,
    ci.company_type
FROM 
    KeywordCount k
    LEFT JOIN CompanyInfo ci ON k.title = ci.title
WHERE 
    k.keyword_count > 0 
ORDER BY 
    k.keyword_count DESC, 
    ci.company_name ASC;
