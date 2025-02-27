WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.id) AS cast_count
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRatedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        ROW_NUMBER() OVER (ORDER BY rm.cast_count DESC) AS ranking
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year = (SELECT MAX(production_year) FROM title)
)
SELECT 
    tm.title,
    tm.production_year,
    c.name AS company_name,
    r.role,
    p.info AS person_info
FROM 
    TopRatedMovies tm
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    person_info p ON ci.person_id = p.person_id
WHERE 
    tm.ranking <= 10;
