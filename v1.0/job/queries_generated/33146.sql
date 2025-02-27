WITH RECURSIVE movie_hierarchy AS (
    -- Base case: select all movies and their immediate cast
    SELECT
        m.id AS movie_id,
        m.title,
        c.person_id,
        c.nr_order,
        1 AS level
    FROM 
        aka_title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    
    UNION ALL
    
    -- Recursive case: select all movies linked via movie_link
    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        c.person_id,
        c.nr_order,
        mh.level + 1 AS level
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        mh.level < 5  -- Limit recursion depth to prevent infinite loops
),
ranked_movies AS (
    -- Window function to rank movies based on the number of unique cast members
    SELECT 
        movie_id,
        title,
        COUNT(DISTINCT person_id) AS unique_cast_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT person_id) DESC) AS rank
    FROM 
        movie_hierarchy
    GROUP BY 
        movie_id, title
)
SELECT 
    r.rank,
    r.title,
    r.unique_cast_count,
    m.production_year,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
FROM 
    ranked_movies r
JOIN 
    aka_title m ON r.movie_id = m.id
LEFT JOIN 
    cast_info ci ON m.id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    m.production_year IS NOT NULL
    AND (m.kind_id = 1 OR m.kind_id = 2)  -- Assuming 1 = Feature, 2 = TV
    AND r.unique_cast_count > 1  -- Filter out movies with only one unique cast member
GROUP BY 
    r.rank, r.title, m.production_year
HAVING 
    COUNT(DISTINCT ak.id) > 3  -- Only include films with more than 3 unique cast members
ORDER BY 
    r.rank;
