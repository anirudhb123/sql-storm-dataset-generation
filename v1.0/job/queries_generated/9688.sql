WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count, 
        keyword_count,
        RANK() OVER (ORDER BY cast_count DESC, keyword_count DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    tm.title,
    tm.production_year,
    p.name AS actor_name,
    c.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS total_companies
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    tm.rank <= 10 
GROUP BY 
    tm.title, tm.production_year, p.name, c.kind
ORDER BY 
    tm.rank, total_companies DESC;
