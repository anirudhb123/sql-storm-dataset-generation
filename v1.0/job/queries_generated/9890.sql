WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title, 
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS movie_rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
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
        actors
    FROM
        RankedMovies
    WHERE
        movie_rank <= 10
)

SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.actors,
    GROUP_CONCAT(DISTINCT mk.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name) AS production_companies
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.total_cast, tm.actors
ORDER BY 
    tm.total_cast DESC;
