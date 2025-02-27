WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        ARRAY_AGG(k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_name,
        keywords
    FROM 
        RankedMovies
    WHERE 
        rn = 1
    ORDER BY 
        production_year DESC
    LIMIT 10
)

SELECT 
    tm.title,
    tm.production_year,
    tm.actor_name,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS aggregated_keywords
FROM 
    TopMovies tm
JOIN 
    UNNEST(tm.keywords) AS kw ON TRUE
GROUP BY 
    tm.title, tm.production_year, tm.actor_name
ORDER BY 
    tm.production_year DESC;
