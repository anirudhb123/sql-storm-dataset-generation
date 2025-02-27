WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year > 2000
    UNION ALL
    SELECT 
        ca.person_id,
        aa.name AS actor_name,
        ta.title AS movie_title,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY ta.production_year DESC) AS rn
    FROM 
        actor_hierarchy ca
    JOIN 
        cast_info c ON ca.person_id = c.person_id
    JOIN 
        aka_name aa ON c.person_id = aa.person_id
    JOIN 
        aka_title ta ON c.movie_id = ta.movie_id
    WHERE 
        ta.production_year IS NOT NULL AND ta.production_year <= (SELECT MAX(production_year) FROM aka_title)
),
agg_movies AS (
    SELECT
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count,
        STRING_AGG(DISTINCT movie_title, ', ') AS all_movies
    FROM 
        actor_hierarchy
    WHERE 
        rn = 1
    GROUP BY 
        actor_name
),
top_actors AS (
    SELECT 
        *,
        NTILE(10) OVER (ORDER BY movie_count DESC) AS tier
    FROM 
        agg_movies
),
inconsistent_names AS (
    SELECT 
        n.id AS name_id, 
        n.name AS inconsistent_name, 
        COUNT(DISTINCT a.person_id) AS actor_count
    FROM 
        name n
    LEFT JOIN 
        aka_name a ON a.name = n.name 
    GROUP BY 
        n.id, n.name
    HAVING 
        COUNT(DISTINCT a.person_id) < 2
)
SELECT 
    ta.actor_name,
    ta.movie_count,
    ta.all_movies,
    in_name.inconsistent_name,
    in_name.actor_count
FROM 
    top_actors ta
LEFT JOIN 
    inconsistent_names in_name ON in_name.actor_count IS NOT NULL
WHERE 
    ta.tier = 1
ORDER BY 
    ta.movie_count DESC;
