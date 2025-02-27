WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
star_actors AS (
    SELECT 
        ak.name AS actor_name, 
        r.role, 
        COUNT(DISTINCT c.movie_id) AS movies_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name, r.role
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
recent_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        m.production_year >= (SELECT MAX(production_year) - 5 FROM aka_title)
    GROUP BY 
        m.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(sa.actor_name, 'Unknown Actor') AS actor_name,
    sa.movies_count,
    rm.actor_names
FROM 
    ranked_movies rm
LEFT JOIN 
    star_actors sa ON rm.movie_id = sa.movies_count
LEFT JOIN 
    recent_movies r ON rm.movie_id = r.movie_id
WHERE 
    rm.rn <= 3
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC
LIMIT 10;
