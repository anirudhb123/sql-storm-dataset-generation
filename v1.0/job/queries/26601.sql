WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        c.kind AS company_type,
        COUNT(DISTINCT a.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS rn
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year, c.kind
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.company_type,
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn = 1
    ORDER BY 
        rm.actor_count DESC
    LIMIT 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_type,
    tm.actor_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actors
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.company_type, tm.actor_count
ORDER BY 
    tm.actor_count DESC;
