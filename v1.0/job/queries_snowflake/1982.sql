
WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year,
        COUNT(DISTINCT c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.title, t.production_year
), 
HighCastTitles AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedTitles 
    WHERE 
        rn <= 5
), 
MovieWithCompany AS (
    SELECT 
        t.title, 
        t.production_year, 
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.title, t.production_year
)

SELECT 
    hct.title,
    hct.production_year,
    mcc.companies,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = (SELECT id FROM aka_title WHERE title = hct.title AND production_year = hct.production_year) AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') AND mi.info IS NOT NULL) AS rating_count
FROM 
    HighCastTitles hct
LEFT JOIN 
    MovieWithCompany mcc ON hct.title = mcc.title AND hct.production_year = mcc.production_year
WHERE 
    mcc.companies IS NOT NULL
ORDER BY 
    hct.production_year DESC, 
    hct.title;
