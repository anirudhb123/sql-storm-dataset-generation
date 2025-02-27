WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_in_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT * 
    FROM RankedMovies 
    WHERE rank_in_year <= 5
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.aka_names,
    tm.keywords,
    c.name AS company_name,
    ct.kind AS company_type
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
