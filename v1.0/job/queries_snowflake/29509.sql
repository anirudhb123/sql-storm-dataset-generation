WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        a.imdb_index,
        k.keyword,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id, a.imdb_index, k.keyword
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        kind_id,
        imdb_index,
        keyword,
        cast_count,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_title,
    tm.production_year,
    kt.kind AS movie_kind,
    tm.keyword,
    tm.cast_count
FROM 
    TopMovies tm
JOIN 
    kind_type kt ON tm.kind_id = kt.id
WHERE 
    tm.rank <= 5
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
