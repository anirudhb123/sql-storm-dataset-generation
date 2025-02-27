WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        ra.name AS director_name,
        COUNT(ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast_size
    FROM
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ra ON mc.company_id = ra.person_id
    GROUP BY 
        mt.title, 
        mt.production_year, 
        ra.name
),
TopDirectors AS (
    SELECT 
        director_name,
        production_year,
        total_cast,
        rank_by_cast_size
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast_size <= 3
)
SELECT 
    td.director_name,
    AVG(CASE 
            WHEN td.total_cast IS NULL THEN NULL
            ELSE td.total_cast 
        END) AS avg_cast_size,
    STRING_AGG(DISTINCT tm.title || ' (' || tm.production_year || ')', ', ') AS related_movies
FROM 
    TopDirectors td
LEFT JOIN 
    aka_title tm ON td.production_year = tm.production_year
WHERE 
    (td.total_cast > 0 OR td.total_cast IS NULL)
GROUP BY 
    td.director_name
HAVING 
    COUNT(DISTINCT td.production_year) >= 2
ORDER BY 
    avg_cast_size DESC
LIMIT 10;

This SQL query performs the following actions:

1. The `WITH` clause creates a common table expression (CTE) called `RankedMovies` that calculates the number of cast members for each movie, ranks them by the size of their cast, and determines the director’s name from the company associated with the movie.

2. A second CTE, `TopDirectors`, filters out only those directors of movies that have the top three cast sizes in their production year.

3. The main query calculates the average cast size for these top directors, concatenates the titles of their related movies, and filters based on the conditions specified.

4. The use of `STRING_AGG` combines movie titles for easy reading, while the `HAVING` clause ensures that only directors who have worked on movies from at least two different years are included. 

5. The results are sorted and limited to the top 10 entries based on the average cast size. 

This structure allows for intricate logic with multiple CTEs, aggregate functions, and various join operations, presenting a complex yet comprehensible SQL query capable of performance benchmarking within the provided schema.
