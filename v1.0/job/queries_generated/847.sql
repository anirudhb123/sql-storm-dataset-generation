WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
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
        rank <= 5
),
CompanyDetails AS (
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
    tm.title,
    tm.production_year,
    cd.company_name,
    cd.company_type,
    COALESCE(ki.keyword, 'No Keywords') AS keywords,
    COALESCE(NULLIF(mii.info, ''), 'No Info') AS movie_info,
    COUNT(ki.id) AS keyword_count
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyDetails cd ON tm.title = (SELECT title FROM aka_title WHERE id = cd.movie_id)
LEFT JOIN 
    movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    movie_info mii ON tm.production_year = mii.movie_id
GROUP BY 
    tm.title, tm.production_year, cd.company_name, cd.company_type, ki.keyword, mii.info
ORDER BY 
    tm.production_year DESC, COUNT(ki.id) DESC, tm.title;
