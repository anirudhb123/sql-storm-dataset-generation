WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        aka_title ak ON ak.movie_id = t.id
    JOIN 
        cast_info c ON c.movie_id = t.id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary') 
        AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%drama%')
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title_id, 
        title, 
        production_year,
        cast_count,
        aka_names,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS ranking
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    STRING_AGG(ak.name, ', ') AS all_aka_names
FROM 
    TopMovies tm
JOIN 
    aka_name ak ON ak.person_id IN (SELECT DISTINCT person_id FROM cast_info WHERE movie_id = tm.title_id)
WHERE 
    tm.ranking <= 10
GROUP BY 
    tm.title, tm.production_year, tm.cast_count
ORDER BY 
    tm.cast_count DESC;
