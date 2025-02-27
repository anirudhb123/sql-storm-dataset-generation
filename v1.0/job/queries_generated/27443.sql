WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.kind_id IN (
            SELECT id FROM kind_type WHERE kind = 'movie'
        )
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_cast_members DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.total_cast_members,
    tm.aka_names,
    tm.keywords
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.production_year DESC,
    tm.total_cast_members DESC;
