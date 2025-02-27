WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM
        aka_title ak
    JOIN
        title t ON ak.movie_id = t.imdb_id
    LEFT JOIN
        cast_info c ON t.imdb_id = c.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY total_cast DESC) AS rank_by_cast
    FROM 
        RankedMovies
    WHERE 
        total_cast > 0
),
TopMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year, 
        total_cast,
        aka_names
    FROM 
        FilteredMovies
    WHERE 
        rank_by_cast <= 10
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.aka_names,
    cn.name AS company_name,
    ct.kind AS company_type
FROM 
    TopMovies tm
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.imdb_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC;
