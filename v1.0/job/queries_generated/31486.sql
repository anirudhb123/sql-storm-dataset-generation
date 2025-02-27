WITH RECURSIVE MovieCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
         
    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        cte.level + 1
    FROM 
        aka_title m
    JOIN 
        MovieCTE cte ON m.id = m.id  -- Self-join to simulate hierarchy
    WHERE 
        cte.level < 5  -- Limiting recursive level for demonstration
)
SELECT 
    m.movie_id,
    m.movie_title,
    m.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    MAX(CASE WHEN ki.keyword = 'Oscar' THEN 1 ELSE 0 END) AS has_oscar,

    -- Using window functions to calculate rank based on the number of cast
    RANK() OVER (ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS cast_rank
FROM 
    MovieCTE m
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    m.movie_title IS NOT NULL
GROUP BY 
    m.movie_id, m.movie_title, m.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 5 -- Filtering for movies with more than 5 unique cast members
ORDER BY 
    m.production_year DESC;
