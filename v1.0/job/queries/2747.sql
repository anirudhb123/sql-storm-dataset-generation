WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
ActorInfo AS (
    SELECT 
        a.name AS actor_name,
        p.info AS actor_info,
        t.title,
        t.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        TopMovies t ON ci.movie_id = t.movie_id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'biography')
)
SELECT 
    t.title,
    t.production_year,
    STRING_AGG(DISTINCT ai.actor_name, ', ') AS actors,
    COUNT(DISTINCT ai.actor_info) AS biography_count
FROM 
    TopMovies t
LEFT JOIN 
    ActorInfo ai ON t.title = ai.title AND t.production_year = ai.production_year
GROUP BY 
    t.title, t.production_year
HAVING 
    COUNT(DISTINCT ai.actor_name) > 2
ORDER BY 
    t.production_year DESC, COUNT(DISTINCT ai.actor_name) DESC;
