WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(k.id) AS keyword_count,
        ARRAY_AGG(DISTINCT c.name) AS company_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(k.id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.keyword_count,
        rm.company_names
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword_count,
    tm.company_names
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.keyword_count DESC;
