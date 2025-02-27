WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year,
        COUNT(cc.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(cc.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast c ON t.id = c.movie_id
    LEFT JOIN 
        cast_info cc ON c.subject_id = cc.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rn <= 5
), 
KeywordCount AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    kc.keyword_count,
    cd.company_names
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordCount kc ON tm.title = (SELECT title FROM aka_title WHERE id = kc.movie_id)
LEFT JOIN 
    CompanyDetails cd ON tm.title = (SELECT title FROM aka_title WHERE id = cd.movie_id)
WHERE 
    kc.keyword_count IS NOT NULL OR cd.company_names IS NOT NULL
ORDER BY 
    tm.production_year DESC, 
    kc.keyword_count DESC;
