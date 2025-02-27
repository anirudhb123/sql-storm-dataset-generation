WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000 -- Filtering for movies from 2000 onwards

    UNION ALL

    SELECT 
        m.id,
        CONCAT(ch.title, ' -> ', m.title) AS title, -- Building a hierarchical title representation
        m.production_year,
        depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.movie_id = m.id
    JOIN 
        MovieHierarchy ch ON ch.movie_id = ml.linked_movie_id
)

SELECT 
    mh.movie_id,
    mh.title AS full_movie_title,
    mh.production_year,
    (SELECT COUNT(*) FROM cast_info c WHERE c.movie_id = mh.movie_id) AS total_cast, 
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mh.movie_id) AS total_keywords,
    COALESCE(s.actors, 0) AS total_actors,  -- Handling potential NULL values from subquery
    COALESCE(k.keywords, 'None') AS keywords_list
FROM 
    MovieHierarchy mh
LEFT JOIN (
    SELECT 
        movie_id,
        COUNT(*) AS actors
    FROM 
        cast_info
    WHERE 
        role_id IS NOT NULL -- Ensuring only valid roles are counted
    GROUP BY 
        movie_id
) s ON s.movie_id = mh.movie_id
LEFT JOIN (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
) k ON k.movie_id = mh.movie_id
WHERE 
    mh.depth <= 2 -- Limiting depth for performance and relevancy
ORDER BY 
    mh.production_year DESC, mh.movie_id;  -- Sorting by year and movie_id for clarity
