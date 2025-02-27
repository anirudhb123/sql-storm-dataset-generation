WITH ranked_movies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(ci.person_id) AS total_actors,
        STRING_AGG(DISTINCT ak.name, ', ') AS akas,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS ranking
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
),
top_actors AS (
    SELECT 
        ak.name, 
        COUNT(DISTINCT ci.movie_id) AS filmography_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title t ON t.id = ci.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
)
SELECT 
    rm.title, 
    rm.production_year, 
    rm.total_actors, 
    rm.akas, 
    rm.keywords,
    ta.name AS top_actor, 
    ta.filmography_count, 
    ta.movies 
FROM 
    ranked_movies rm
JOIN 
    top_actors ta ON ta.movies LIKE '%' || rm.title || '%' 
WHERE 
    rm.ranking <= 5
ORDER BY 
    rm.production_year, rm.total_actors DESC;
