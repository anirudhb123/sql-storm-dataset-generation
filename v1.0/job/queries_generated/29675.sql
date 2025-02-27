WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS total_cast,
        STRING_AGG(a.name, ', ') AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        cast_names
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)

SELECT 
    tm.title AS movie_title,
    tm.production_year,
    tm.total_cast,
    tm.cast_names,
    GROUP_CONCAT(DISTINCT kc.keyword ORDER BY kc.keyword) AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.total_cast, tm.cast_names
ORDER BY 
    tm.production_year DESC, tm.total_cast DESC;

This query first identifies the top 5 movies with the most cast members for each production year using a Common Table Expression (CTE) called `RankedMovies`. It then aggregates the names of the cast members into a comma-separated string. After that, in the second CTE `TopMovies`, we retrieve the necessary details of these top movies. Finally, it retrieves the movie titles along with their associated production years, total cast count, cast names, keywords, and production companies in an elaborate final selection statement.
