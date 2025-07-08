WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary') 
        AND t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        cast_count DESC
    LIMIT 10
),
TopActors AS (
    SELECT 
        n.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name n
    JOIN 
        cast_info ci ON n.person_id = ci.person_id
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
    GROUP BY 
        n.name
    ORDER BY 
        movie_count DESC
    LIMIT 5
)
SELECT 
    rm.title,
    rm.production_year,
    ta.actor_name,
    ta.movie_count
FROM 
    RankedMovies rm
JOIN 
    TopActors ta ON ta.movie_count > 0
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;