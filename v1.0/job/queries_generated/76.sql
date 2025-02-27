WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
), TopMovies AS (
    SELECT 
        movie_id, title, production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
), GenreCounts AS (
    SELECT 
        k.keyword AS genre, 
        COUNT(m.movie_id) AS movie_count 
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        k.keyword
), CompanyCounts AS (
    SELECT 
        c.name AS company_name, 
        COUNT(mc.movie_id) AS movie_count 
    FROM 
        company_name c
    LEFT JOIN 
        movie_companies mc ON c.id = mc.company_id
    GROUP BY 
        c.name
)
SELECT 
    tm.title,
    COALESCE(gc.genre, 'Other') AS genre,
    COALESCE(cc.company_name, 'Independent') AS company,
    tm.production_year,
    tm.total_cast
FROM 
    TopMovies tm
LEFT JOIN 
    GenreCounts gc ON tm.movie_id = (SELECT mk.movie_id FROM movie_keyword mk WHERE mk.movie_id = tm.movie_id LIMIT 1)
LEFT JOIN 
    CompanyCounts cc ON tm.movie_id = (SELECT mc.movie_id FROM movie_companies mc WHERE mc.movie_id = tm.movie_id LIMIT 1)
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC;
