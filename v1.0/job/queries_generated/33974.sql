WITH RECURSIVE MovieChain AS (
    -- Start with the main movies that have a certain keyword
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title,
        1 AS chain_length
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mk.movie_id = mt.id
    JOIN 
        keyword k ON k.id = mk.keyword_id 
    WHERE 
        k.keyword = 'Action'

    UNION ALL

    -- Recursively find linked movies through movie_link
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        mc.chain_length + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON at.id = ml.linked_movie_id
    JOIN 
        MovieChain mc ON ml.movie_id = mc.movie_id
)
SELECT 
    mc.movie_id,
    mc.movie_title,
    mc.chain_length,
    ac.name AS actor_name,
    COUNT(DISTINCT mc2.movie_id) AS linked_movie_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS associated_keywords
FROM 
    MovieChain mc
LEFT JOIN 
    cast_info ci ON ci.movie_id = mc.movie_id
LEFT JOIN 
    aka_name ac ON ac.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mc.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id

-- Grouping to collate related information together
GROUP BY 
    mc.movie_id, mc.movie_title, ac.name, mc.chain_length
HAVING 
    COUNT(DISTINCT mc2.movie_id) > 5  -- Only movies that are linked to more than 5 other movies
ORDER BY 
    mc.chain_length DESC, 
    linked_movie_count DESC;

This SQL query utilizes recursive Common Table Expressions (CTEs) to create a chain of linked movies starting from an anchor movie defined by its keyword. It retrieves additional information about actors involved in those movies alongside a count of linked movies and associated keywords. The results are organized by the chain length and number of links.
