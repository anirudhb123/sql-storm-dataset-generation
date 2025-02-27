WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        aka_names
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.aka_names,
    COUNT(DISTINCT m.id) AS num_companies,
    STRING_AGG(DISTINCT c.name, ', ') AS company_names,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (
        SELECT id FROM title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1
    )
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (
        SELECT id FROM title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1
    )
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    tm.title, tm.production_year, tm.aka_names
ORDER BY 
    production_year DESC;
