WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        t.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id 
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id 
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id 
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000 AND 
        cn.country_code = 'USA'
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        cast_count > 0
)

SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actor_names
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;

This SQL query benchmarks string processing by calculating the number of distinct actors per movie along with their names, filtering by movies produced in the USA after the year 2000, and returns the top 10 movies with the highest number of cast members.
