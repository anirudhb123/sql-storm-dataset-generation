WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        c.name AS company_name,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id, c.name
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        company_name,
        keywords
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.company_name,
    tm.keywords
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC;
