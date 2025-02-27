WITH ranked_movies AS (
    SELECT 
        a.id AS aka_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mi.info) AS info_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mi.info) DESC) AS rank_by_infoCount
    FROM
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        a.id, t.title, t.production_year
),
best_movies AS (
    SELECT 
        title,
        production_year
    FROM 
        ranked_movies
    WHERE 
        rank_by_infoCount = 1
),
actors AS (
    SELECT 
        DISTINCT ak.name AS actor_name,
        c.nr_order,
        t.title AS movie_title
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        aka_title a ON c.movie_id = a.movie_id
    JOIN 
        title t ON a.movie_id = t.id
    WHERE 
        ak.name IS NOT NULL
),
filtered_actors AS (
    SELECT 
        actor_name,
        movie_title,
        ROW_NUMBER() OVER (PARTITION BY actor_name ORDER BY nr_order) AS actor_rank
    FROM 
        actors
    WHERE 
        movie_title IN (SELECT title FROM best_movies)
)
SELECT 
    b.production_year,
    COUNT(DISTINCT fa.actor_name) AS unique_actors,
    STRING_AGG(DISTINCT fa.movie_title, ', ') AS movies_included
FROM 
    filtered_actors fa
JOIN 
    best_movies b ON fa.movie_title = b.title
GROUP BY 
    b.production_year
ORDER BY 
    b.production_year DESC
HAVING 
    COUNT(DISTINCT fa.actor_name) > 5 AND
    (COUNT(DISTINCT fa.actor_name) < 15 OR 
    (SELECT COUNT(*) FROM filtered_actors WHERE actor_rank = 1) > 10)
    OR 
    (EXISTS (SELECT 1 FROM title t WHERE t.production_year = b.production_year AND t.kind_id IS NULL));

