WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) as year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
ActorCounts AS (
    SELECT 
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
)
SELECT 
    tm.title, 
    tm.production_year, 
    ac.name AS leading_actor, 
    ac.movie_count
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.title = ci.movie_id
JOIN 
    ActorCounts ac ON ci.person_id = ac.person_id
WHERE 
    tm.total_cast IS NOT NULL
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC;
