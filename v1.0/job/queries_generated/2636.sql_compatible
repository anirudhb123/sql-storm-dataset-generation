
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
LatestMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 3
)
SELECT 
    lm.title,
    lm.production_year,
    COALESCE(string_agg(DISTINCT k.keyword, ', '), 'None') AS keywords,
    COUNT(DISTINCT cc.id) AS cast_count
FROM 
    LatestMovies lm
LEFT JOIN 
    movie_keyword mk ON lm.production_year = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON lm.production_year = cc.movie_id
LEFT JOIN 
    movie_companies mc ON lm.production_year = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    co.country_code IS NOT NULL
    OR co.name IS NOT NULL
GROUP BY 
    lm.title, lm.production_year
ORDER BY 
    lm.production_year DESC, lm.title;
