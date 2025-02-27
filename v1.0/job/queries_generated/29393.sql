WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        aka_names
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.aka_names,
    ct.kind AS company_type,
    COUNT(m.id) AS company_count
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    tm.title, tm.production_year, tm.cast_count, tm.aka_names, ct.kind
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
