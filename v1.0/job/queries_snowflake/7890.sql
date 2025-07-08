
WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        company_count,
        keyword_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_count,
    tm.keyword_count,
    LISTAGG(DISTINCT an.name, ',') AS actor_names
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id LIMIT 1)
JOIN 
    aka_name an ON ci.person_id = an.person_id
GROUP BY 
    tm.title, tm.production_year, tm.company_count, tm.keyword_count
ORDER BY 
    tm.production_year DESC, tm.company_count DESC;
