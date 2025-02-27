WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(k.id) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),

TopActors AS (
    SELECT 
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movies_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
    ORDER BY 
        movies_count DESC
    LIMIT 10
),

MoviesWithTopActors AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.actor_name
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        a.name IN (SELECT actor_name FROM TopActors)
)

SELECT 
    m.title, 
    m.production_year, 
    ra.keyword_count, 
    a.actor_name
FROM 
    MoviesWithTopActors m
JOIN 
    RankedTitles ra ON m.movie_id = ra.title_id
JOIN 
    TopActors a ON m.actor_name = a.actor_name
ORDER BY 
    ra.keyword_count DESC, 
    m.production_year DESC;
