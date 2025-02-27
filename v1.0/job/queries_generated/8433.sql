WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(CAST.id) AS cast_count
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info CAST ON cc.subject_id = CAST.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    ak.name AS actor_name,
    ct.kind AS cast_type
FROM 
    TopMovies tm
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    cast_info ci ON mc.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    tm.rank <= 10
AND 
    tm.production_year >= 2000
ORDER BY 
    tm.cast_count DESC, tm.production_year DESC;
