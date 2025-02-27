
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT aka.name, ', ') AS cast_names
    FROM 
        aka_title AS m
    JOIN 
        complete_cast AS cc ON m.id = cc.movie_id
    JOIN 
        cast_info AS c ON cc.subject_id = c.id
    JOIN 
        aka_name AS aka ON c.person_id = aka.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),

TopRankedMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count, 
        cast_names,
        RANK() OVER (ORDER BY cast_count DESC) AS rnk
    FROM 
        RankedMovies
)

SELECT 
    tr.title, 
    tr.production_year, 
    tr.cast_count, 
    tr.cast_names, 
    m.info AS movie_info
FROM 
    TopRankedMovies AS tr
JOIN 
    movie_info AS m ON tr.movie_id = m.movie_id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre') 
    AND tr.rnk <= 10
ORDER BY 
    tr.rnk;
