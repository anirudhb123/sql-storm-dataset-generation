WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
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
        rn <= 5
),
CompanyNames AS (
    SELECT 
        cn.name, 
        GROUP_CONCAT(DISTINCT kt.keyword) AS keywords
    FROM 
        company_name cn
    JOIN 
        movie_companies mc ON cn.id = mc.company_id
    JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        cn.name
)
SELECT 
    tm.title, 
    tm.production_year, 
    cn.name AS company_name, 
    cn.keywords, 
    COALESCE(mi.info, 'No info') AS movie_info
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
LEFT JOIN 
    company_names cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON tm.title = (SELECT title FROM aka_title WHERE id = mi.movie_id)
WHERE 
    cn.name IS NOT NULL
  AND 
    (mi.info IS NULL OR mi.info != '')
ORDER BY 
    tm.production_year DESC, 
    tm.title;
