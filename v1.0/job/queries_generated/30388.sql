WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mt.kind, 'Unknown') AS movie_kind,
        1 AS depth
    FROM 
        aka_title m
    LEFT JOIN 
        kind_type mt ON m.kind_id = mt.id
    WHERE 
        m.production_year >= 2000   -- Filtering for movies produced from 2000 onwards

    UNION ALL

    SELECT 
        m2.id,
        m2.title,
        m2.production_year,
        COALESCE(mt2.kind, 'Unknown'),
        mh.depth + 1
    FROM 
        movie_link ml
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    INNER JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    LEFT JOIN 
        kind_type mt2 ON m2.kind_id = mt2.id
    WHERE 
        mh.depth < 5  -- Limiting depth for recursive links
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    ARRAY_AGG(DISTINCT mh.title ORDER BY mh.production_year DESC) AS movie_titles,
    AVG(mh.production_year) AS avg_production_year,
    MAX(mh.production_year) AS latest_production_year,
    CASE 
        WHEN COUNT(DISTINCT c.movie_id) = 0 THEN 'No Movies'
        ELSE 'Active Actor'
    END AS actor_status
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
GROUP BY 
    a.id
HAVING 
    AVG(mh.production_year) > 2015
ORDER BY 
    total_movies DESC
LIMIT 10;

-- Additional part for benchmarking with set operators
SELECT 
    DISTINCT 'Old Movies' AS category,
    m.title, 
    m.production_year
FROM 
    aka_title m
WHERE 
    m.production_year < 2000

UNION ALL

SELECT 
    DISTINCT 'Recent Movies' AS category,
    m.title, 
    m.production_year
FROM 
    aka_title m
WHERE 
    m.production_year >= 2000
ORDER BY 
    production_year DESC;
