WITH movie_years AS (
    SELECT 
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT m.id) AS company_count
    FROM 
        aka_title t
    JOIN 
        movie_companies m ON t.id = m.movie_id
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.production_year
),
actor_movies AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT title.id) AS movies_played
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title title ON ci.movie_id = title.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
),
top_actors AS (
    SELECT 
        name,
        movies_played,
        RANK() OVER (ORDER BY movies_played DESC) AS actor_rank
    FROM 
        actor_movies
)
SELECT 
    my.production_year,
    my.actor_count,
    my.company_count,
    COALESCE(ta.name, 'Unknown Actor') AS actor,
    COALESCE(ta.movies_played, 0) AS movies_played
FROM 
    movie_years my
LEFT JOIN 
    top_actors ta ON my.actor_count = ta.actor_rank
ORDER BY 
    my.production_year DESC, my.actor_count DESC
LIMIT 10;
