WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title AS m
    JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        cast_info AS c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.keyword,
    (SELECT GROUP_CONCAT(CASE WHEN r.role IS NOT NULL THEN r.role ELSE 'Unknown' END, ', ') 
     FROM cast_info ci
     JOIN role_type r ON ci.person_role_id = r.id 
     WHERE ci.movie_id = tm.movie_id) AS cast_roles
FROM 
    TopMovies tm
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    co.country_code = 'USA'
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;

This query benchmarks string processing by aggregating data of movies and their associated information from various tables. It computes the top 5 keywords for each movie, counts the number of cast members, and retrieves relevant roles associated with each movie while filtering for movies produced in the USA. The output is ordered by production year and the number of cast members to highlight popular films.
