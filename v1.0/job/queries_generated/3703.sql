WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id,
        at.title,
        at.production_year
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
KeywordInfo AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    ki.keywords,
    co.company_count,
    co.companies
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordInfo ki ON tm.production_year = (SELECT production_year FROM aka_title WHERE id = ki.movie_id)
LEFT JOIN 
    CompanyInfo co ON tm.production_year = (SELECT production_year FROM aka_title WHERE id = co.movie_id)
WHERE 
    tm.production_year IS NOT NULL
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
