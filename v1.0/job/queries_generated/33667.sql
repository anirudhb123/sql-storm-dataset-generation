WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        1 AS depth
    FROM 
        cast_info ci
    JOIN 
        aka_title at ON ci.movie_id = at.id
    WHERE 
        at.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ci.person_id,
        ci.movie_id,
        ah.depth + 1
    FROM 
        cast_info ci
    JOIN 
        ActorHierarchy ah ON ci.movie_id = ah.movie_id
    WHERE 
        ah.depth < 3
),
FrequentActors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ah.movie_id) AS movie_count
    FROM 
        ActorHierarchy ah
    JOIN 
        aka_name ak ON ak.person_id = ah.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT ah.movie_id) > 5
),
HighestRatedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        COALESCE(mi.info, 'No Rating') AS rating
    FROM 
        aka_title at
    LEFT JOIN 
        movie_info mi ON at.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
)
SELECT 
    f.actor_name,
    h.title,
    h.production_year,
    COALESCE(h.rating, 'N/A') AS movie_rating,
    ROW_NUMBER() OVER (PARTITION BY f.actor_name ORDER BY h.production_year DESC) AS rank
FROM 
    FrequentActors f
JOIN 
    cast_info ci ON f.actor_name = (SELECT name FROM aka_name WHERE person_id = ci.person_id LIMIT 1)
JOIN 
    HighestRatedTitles h ON ci.movie_id = h.id
WHERE 
    h.production_year > 2010
ORDER BY 
    f.actor_name, rank;
