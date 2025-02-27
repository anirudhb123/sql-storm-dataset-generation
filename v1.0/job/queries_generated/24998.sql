WITH RECURSIVE MovieChain AS (
    -- Start with the root movies, selecting titles produced in the last decade
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS chain_level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 10

    UNION ALL
    
    -- Recursively find linked movies using the movie_link table
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mc.chain_level + 1
    FROM 
        MovieChain mc
    JOIN 
        movie_link ml ON mc.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

-- Final query to aggregate results
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS total_linked_movies,
    AVG(mc.chain_level) AS avg_chain_level,
    STRING_AGG(DISTINCT t.title, ', ') AS titles_in_chain
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    MovieChain mc ON ci.movie_id = mc.movie_id
JOIN 
    aka_title t ON ci.movie_id = t.id
WHERE 
    ak.name IS NOT NULL -- Ensure no null actor names
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 0 -- Only include actors linked to movies in chain
ORDER BY 
    total_linked_movies DESC
LIMIT 10;

-- Add an additional interesting angle with string declaration and NULL handling
SELECT 
    actor_name, 
    total_linked_movies,
    COALESCE(NULLIF(avg_chain_level, 1), 'N/A') AS avg_chain_level_modified,
    CASE 
        WHEN total_linked_movies IS NULL THEN 'No Linked Movies'
        ELSE 'Linked Movies Exist'
    END AS link_status
FROM (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT mc.movie_id) AS total_linked_movies,
        AVG(mc.chain_level) AS avg_chain_level
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        MovieChain mc ON ci.movie_id = mc.movie_id
    GROUP BY 
        ak.name
) AS base
ORDER BY 
    total_linked_movies DESC
LIMIT 5;

-- Combine via UNION to show both details in one query
SELECT * FROM (
    /*... (first complex aggregation from above) ...*/
) UNION ALL SELECT * FROM (
    /*... (second query showing link status and handling) ...*/
);
