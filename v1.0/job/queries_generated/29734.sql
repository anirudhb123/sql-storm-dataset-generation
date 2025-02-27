WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS alias_names,
        STRING_AGG(DISTINCT m_key.keyword, ', ') AS keywords
    FROM 
        aka_title a_t
    JOIN 
        title m ON a_t.movie_id = m.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword m_key ON m.id = m_key.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.rank,
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    tm.alias_names,
    tm.keywords
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10 
ORDER BY 
    tm.rank;
