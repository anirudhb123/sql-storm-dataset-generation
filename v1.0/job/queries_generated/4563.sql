WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT *
    FROM RankedMovies
    WHERE rank_by_cast <= 5
),
MovieKeywords AS (
    SELECT 
        tm.movie_title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title AND production_year = tm.production_year LIMIT 1)
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        tm.movie_title
)
SELECT 
    tm.movie_title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(cn.name, 'Unknown Company') AS production_company,
    (SELECT AVG(info.year_released) FROM movie_info info WHERE info.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title LIMIT 1)) AS avg_year_released
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title AND production_year = tm.production_year LIMIT 1)
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
