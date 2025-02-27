WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.company_id) AS production_companies_count,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_companies m ON t.id = m.movie_id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT m.company_id) > 2 -- filter movies with more than 2 production companies
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        production_companies_count,
        cast_names,
        keywords
    FROM 
        RankedMovies
    WHERE 
        rank <= 10 -- Get the top 10 movies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.production_companies_count,
    tm.cast_names,
    tm.keywords,
    pi.info AS person_info
FROM 
    TopMovies tm
LEFT JOIN 
    person_info pi ON tm.cast_names::text ILIKE '%' || pi.info || '%' -- Include person info related to cast names
ORDER BY 
    tm.production_year DESC, tm.title;
