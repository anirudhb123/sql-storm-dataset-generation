WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        keyword, 
        keyword_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_title, 
    tm.production_year,
    tm.keyword,
    a.name AS actor_name,
    COUNT(c.id) AS cast_count
FROM 
    TopMovies tm
JOIN 
    movie_info mi ON tm.movie_title = mi.info
JOIN 
    complete_cast cc ON mi.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    tm.rank <= 5
    AND a.name IS NOT NULL
GROUP BY 
    tm.movie_title, tm.production_year, tm.keyword, a.name
ORDER BY 
    tm.production_year DESC, 
    tm.keyword_count DESC;

This SQL query does the following:
1. **RankedMovies** Common Table Expression (CTE) aggregates the movie titles along with their production years and associated keywords, counting how many times each keyword is used within each movie.
2. **TopMovies** CTE ranks the movies per production year based on the number of keywords.
3. The final SELECT statement retrieves the top movies, their keywords, and the actors associated with those films, while also counting the number of cast members involved. 
4. The results are filtered to include only the top 5 movies per production year and ordered by production year descending and keyword count descending.
