WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count, 
        aka_names,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.cast_count, 
    tm.aka_names,
    p.info AS director_info
FROM 
    TopMovies tm
JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'director')
LEFT JOIN 
    person_info p ON mi.movie_id = p.person_id
WHERE 
    tm.rank <= 5
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
