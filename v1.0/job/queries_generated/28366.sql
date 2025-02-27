WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        m.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title AS t
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        cast_info AS c ON t.id = c.movie_id
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    WHERE 
        cn.country_code = 'USA' 
        AND m.production_year >= 2000
    GROUP BY 
        t.id, t.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_count,
        cast_names,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_title,
    production_year,
    cast_count,
    cast_names
FROM 
    TopMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year, rank;
