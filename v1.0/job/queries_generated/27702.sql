WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT m.company_id) AS company_count,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT m.company_id) DESC, COUNT(DISTINCT k.keyword) DESC) AS rank_within_year
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies m ON a.id = m.movie_id
    LEFT JOIN 
        movie_keyword k ON a.id = k.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),

TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        company_count,
        keyword_count
    FROM 
        RankedMovies
    WHERE 
        rank_within_year <= 5
)

SELECT 
    tm.movie_title,
    tm.production_year,
    tm.company_count,
    tm.keyword_count,
    STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
    STRING_AGG(DISTINCT co.name, ', ') AS company_names,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    aka_name an ON cc.subject_id = an.person_id
LEFT JOIN 
    company_name co ON co.id IN (SELECT company_id FROM movie_companies WHERE movie_id = tm.movie_id)
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = tm.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    tm.movie_id, tm.movie_title, tm.production_year, tm.company_count, tm.keyword_count
ORDER BY 
    tm.production_year DESC, tm.company_count DESC;
