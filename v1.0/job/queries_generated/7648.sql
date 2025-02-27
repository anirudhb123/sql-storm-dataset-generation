WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ki.id) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        keyword_count,
        RANK() OVER (ORDER BY keyword_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    cn.name AS company_name,
    ct.kind AS company_type,
    ci.role_id,
    COUNT(ci.id) AS cast_count
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.title, tm.production_year, cn.name, ct.kind, ci.role_id
ORDER BY 
    tm.keyword_count DESC, tm.production_year;
