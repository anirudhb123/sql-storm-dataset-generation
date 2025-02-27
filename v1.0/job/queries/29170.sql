WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mk.movie_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        title_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
    STRING_AGG(DISTINCT c.name, ', ') AS company_names
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.title_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    movie_companies mc ON tm.title_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
GROUP BY 
    tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC;
