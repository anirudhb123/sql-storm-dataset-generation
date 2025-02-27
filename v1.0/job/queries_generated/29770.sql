WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(cc.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(cc.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info cc ON t.id = cc.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023 
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
TopMovies AS (
    SELECT movie_id, title, production_year, keyword, cast_count
    FROM RankedMovies
    WHERE rn = 1
    ORDER BY cast_count DESC
    LIMIT 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword,
    cn.name AS company_name,
    ci.role AS cast_role
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    role_type ci ON cc.role_id = ci.id
ORDER BY 
    tm.cast_count DESC;
