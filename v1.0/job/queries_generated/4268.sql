WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
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
CompanyDetails AS (
    SELECT 
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    LEFT JOIN 
        company_name co ON m.company_id = co.id
    LEFT JOIN 
        company_type ct ON m.company_type_id = ct.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cd.company_name, 'Independent') AS production_company,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    SUM(CASE WHEN i.info_type_id = 1 THEN 1 ELSE 0 END) AS has_budget_info
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.title = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON tm.title = mi.movie_id
LEFT JOIN 
    CompanyDetails cd ON tm.title = cd.movie_id
LEFT JOIN 
    movie_info_idx i ON tm.title = i.movie_id
GROUP BY 
    tm.title, tm.production_year, cd.company_name
HAVING 
    COUNT(DISTINCT k.keyword) > 0
ORDER BY 
    tm.production_year DESC, keyword_count DESC;
