WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        keywords, 
        cast_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keywords,
    tm.cast_count,
    COUNT(DISTINCT p.id) AS unique_persons,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON cc.movie_id IN (SELECT id FROM aka_title WHERE title = tm.title)
JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
JOIN 
    aka_name p ON p.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = cc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.title, tm.production_year, tm.keywords, tm.cast_count
ORDER BY 
    tm.cast_count DESC;
