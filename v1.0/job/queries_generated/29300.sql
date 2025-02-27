WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title ak
    JOIN 
        title m ON ak.movie_id = m.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year, 
        total_cast, 
        aka_names,
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.aka_names,
    mci.info
FROM 
    TopMovies tm
JOIN 
    movie_info mci ON tm.movie_id = mci.movie_id
JOIN 
    info_type it ON mci.info_type_id = it.id
WHERE 
    it.info = 'Plot'
    AND tm.rank <= 10
ORDER BY 
    tm.total_cast DESC;

This SQL query benchmarks string processing by aggregating and analyzing data from multiple tables, focusing on the movie cast and related names. It ranks the top 10 movies based on the number of distinct cast members, retrieves their alternate names, and fetches plot information from the relevant tables.
