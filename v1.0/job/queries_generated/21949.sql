WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
MovieKeywords AS (
    SELECT 
        m.title,
        k.keyword
    FROM 
        TopMovies m
    JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = m.title LIMIT 1)
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompanyStats AS (
    SELECT 
        c.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON mc.company_id = c.id
    GROUP BY 
        c.name
    HAVING 
        COUNT(DISTINCT mc.movie_id) > 1
),
NullHandling AS (
    SELECT 
        m.title,
        COALESCE(k.keyword, 'No Keyword') AS keyword_label,
        cs.company_name,
        CS.movie_count
    FROM 
        MovieKeywords k
    LEFT JOIN 
        CompanyStats cs ON k.title = cs.company_name
),
FinalOutput AS (
    SELECT 
        n.title,
        n.keyword_label,
        n.company_name,
        SUM(COALESCE(n.movie_count, 0)) OVER (PARTITION BY n.title) AS total_movies_by_company
    FROM 
        NullHandling n
)
SELECT 
    title,
    keyword_label,
    company_name,
    total_movies_by_company
FROM 
    FinalOutput
WHERE 
    title IS NOT NULL
ORDER BY 
    production_year DESC NULLS LAST,
    keyword_label;
