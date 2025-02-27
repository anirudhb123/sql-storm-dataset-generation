WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_title ak ON ak.movie_id = m.id
    GROUP BY 
        m.id
    HAVING 
        m.production_year >= 2000
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        num_cast_members,
        aka_names,
        RANK() OVER (ORDER BY num_cast_members DESC, production_year DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.num_cast_members,
    tm.aka_names,
    COALESCE(COUNT(DISTINCT mc.company_id), 0) AS num_companies,
    COALESCE(STRING_AGG(DISTINCT cn.name, ', '), 'No Companies') AS company_names
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.num_cast_members, tm.aka_names
ORDER BY 
    tm.rank;

This SQL query benchmarks string processing by extracting the top 10 movies released since 2000 based on the number of cast members. It uses common table expressions (CTEs) to rank the movies and collect aka names. The final selection also gathers company names associated with those movies, showcasing string aggregation via `STRING_AGG` for names and companies.
