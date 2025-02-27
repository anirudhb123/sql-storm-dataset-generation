WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        ct.kind AS company_type,
        a.name AS actor_name,
        COUNT(ci.id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY mt.production_year DESC) AS rn
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year, ct.kind, a.name
    HAVING 
        COUNT(ci.id) > 5
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        company_type,
        actor_name,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rn = 1
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_type,
    tm.actor_name,
    tm.total_cast,
    STRING_AGG(tm.actor_name, ', ' ORDER BY tm.actor_name) AS all_actors
FROM 
    TopMovies tm
GROUP BY 
    tm.title, tm.production_year, tm.company_type, tm.total_cast
ORDER BY 
    tm.production_year DESC, tm.total_cast DESC;
