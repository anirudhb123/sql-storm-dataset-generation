WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword AS k ON k.id = mk.keyword_id
    LEFT JOIN 
        cast_info AS c ON c.movie_id = t.id
    LEFT JOIN 
        aka_name AS ak ON ak.person_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        aka_names,
        keywords,
        cast_count,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id, 
    tm.title, 
    tm.production_year, 
    tm.aka_names,
    tm.keywords,
    tm.cast_count
FROM 
    TopMovies AS tm
WHERE 
    tm.rank <= 5
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;