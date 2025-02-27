WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        title t
    JOIN 
        aka_title at ON at.movie_id = t.id
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name an ON an.person_id = ci.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year,
        actor_count,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names
FROM 
    TopMovies tm
JOIN 
    movie_companies mc ON mc.movie_id = tm.movie_id
JOIN 
    company_name cn ON cn.id = mc.company_id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.actor_count
ORDER BY 
    tm.actor_count DESC;
