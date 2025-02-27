WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        RANK() OVER (ORDER BY cast_count DESC) AS ranking
    FROM 
        RankedMovies
    WHERE 
        production_year BETWEEN 2000 AND 2023
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
    GROUP_CONCAT(DISTINCT cn.name) AS company_names,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    aka_title ak ON tm.movie_id = ak.movie_id
WHERE 
    tm.ranking <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count
ORDER BY 
    tm.cast_count DESC;
