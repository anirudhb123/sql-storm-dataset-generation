WITH RECURSIVE related_movies AS (
    -- Base case: Select a movie and its immediate connections
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        1 AS level
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id = 1  -- Assuming 1 represents "directly links to"

    UNION ALL

    -- Recursive case: Get all related movies through their links
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        rm.level + 1
    FROM 
        movie_link ml
    JOIN 
        related_movies rm ON ml.movie_id = rm.linked_movie_id
)

-- Main query: Fetch movie details alongside their cast and keywords
SELECT 
    ak.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    k.keyword,
    STRING_AGG(DISTINCT cct.kind, ', ') AS company_types,
    AVG(mi.info::numeric) FILTER (WHERE iti.info = 'rating') AS average_rating,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY t.production_year DESC) AS movie_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type cct ON mc.company_type_id = cct.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type iti ON mi.info_type_id = iti.id
WHERE 
    t.production_year IS NOT NULL
    AND ak.name IS NOT NULL
    AND (mi.note IS NULL OR mi.note NOT LIKE '%deleted%')  -- Exclude deleted notes
GROUP BY 
    ak.name, t.title, t.production_year, k.keyword
HAVING 
    COUNT(DISTINCT t.id) > 1  -- Only include actors with more than one movie
ORDER BY 
    actor_name, production_year DESC;

This SQL query combines various complex SQL constructs to retrieve interesting information about actors, the movies they have acted in, the companies involved in those movies, keywords associated with those movies, and average ratings while ensuring to maintain performance benchmarking through filtering and grouping.
