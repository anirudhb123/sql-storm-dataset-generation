
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords_list, 'No keywords') AS keywords,
    ak.name AS actor_name,
    ct.kind AS company_type
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = (SELECT id FROM title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
LEFT JOIN 
    cast_info ci ON ci.movie_id = (SELECT id FROM title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
WHERE 
    ct.kind IS NOT NULL OR mk.keywords_list IS NULL
ORDER BY 
    tm.production_year DESC, tm.title;
