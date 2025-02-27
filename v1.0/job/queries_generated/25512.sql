WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS c ON t.movie_id = c.movie_id
    JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        num_cast_members,
        aka_names,
        ROW_NUMBER() OVER (ORDER BY num_cast_members DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        num_cast_members > 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.num_cast_members,
    STRING_AGG(tm.aka_names::text, ', ') AS all_aka_names
FROM 
    TopMovies AS tm
JOIN 
    movie_info AS mi ON mi.movie_id = tm.movie_id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Rating')
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.num_cast_members
ORDER BY 
    tm.num_cast_members DESC
LIMIT 10;
