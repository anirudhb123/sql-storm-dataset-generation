WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL AND m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
cast_with_roles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    STRING_AGG(DISTINCT cwr.actor_name || ' (' || cwr.role || ')', ', ') AS actors,
    COUNT(DISTINCT cwr.actor_name) AS actor_count,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_with_roles cwr ON mh.movie_id = cwr.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.level <= 2
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT cwr.actor_name) > 1
ORDER BY 
    mh.production_year DESC, actor_count DESC;
This SQL query constructs a recursive common table expression (`CTE`) to create a hierarchy of movies linked through the `movie_link` table. 

Additionally, it pulls in information about the cast and their roles from the `cast_info`, `aka_name`, and `role_type` tables, using a window function to rank actors by their order in a movie.

The final selection aggregates the names and roles of the actors in each movie, counting unique actors and associated keywords, and filters results to include only those movies that have more than one actor listed. The output is sorted by production year and actor count.
