WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
RecentMovies AS (
    SELECT 
        movie_title,
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        production_year > (SELECT MAX(production_year) - 10 FROM aka_title)
),
TopCast AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    INNER JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.total_cast,
    tc.actor_name,
    COALESCE(tc.movie_count, 0) AS actor_movie_count
FROM 
    RecentMovies rm
LEFT JOIN 
    TopCast tc ON rm.movie_title LIKE '%' || tc.actor_name || '%'
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast DESC
LIMIT 20;
