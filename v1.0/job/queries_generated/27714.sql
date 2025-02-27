WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),

FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        cast_count > 5 -- only movies with more than 5 cast members
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        cast_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        FilteredMovies
)

SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    GROUP_CONCAT(DISTINCT akn.name ORDER BY akn.name) AS cast_names,
    k.keyword AS movie_keyword
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN 
    aka_name akn ON ci.person_id = akn.person_id
JOIN 
    keyword k ON tm.keyword = k.keyword
WHERE 
    tm.rank <= 10 -- top 10 movies
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count, k.keyword
ORDER BY 
    tm.cast_count DESC;
