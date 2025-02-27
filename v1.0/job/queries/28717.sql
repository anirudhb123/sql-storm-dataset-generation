WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year >= 2000 AND m.production_year <= 2023
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_count,
        actor_names
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    tm.actor_names,
    p.info AS additional_info
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    person_info p ON p.person_id = (SELECT id FROM aka_name WHERE name LIKE '%Smith%' LIMIT 1) 
WHERE 
    it.info = 'summary'
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;