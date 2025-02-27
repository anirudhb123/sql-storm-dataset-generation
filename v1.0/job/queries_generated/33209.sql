WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year, 
        m.name AS company_name,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id, 
        mh.movie_title, 
        mh.production_year, 
        m.name AS company_name,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    WHERE 
        mh.level < 5  -- Limit recursion depth
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.company_name,
        ROW_NUMBER() OVER (PARTITION BY mh.company_name ORDER BY mh.production_year DESC) AS rn
    FROM 
        MovieHierarchy mh
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.company_name
FROM 
    RankedMovies rm
WHERE 
    rn <= 3  -- Get top 3 movies per company
ORDER BY 
    rm.company_name,
    rm.production_year DESC;

-- Additional Queries for Performance Benchmarking
SELECT 
    c.person_id, 
    COUNT(DISTINCT ca.movie_id) AS movie_count,
    SUM(CASE WHEN ca.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS roles_assigned
FROM 
    cast_info ca
JOIN 
    aka_name c ON ca.person_id = c.person_id
LEFT JOIN 
    movie_info mi ON ca.movie_id = mi.movie_id
WHERE 
    c.name IS NOT NULL 
    AND mi.note IS NULL  -- Filtering for movies with no additional notes
GROUP BY 
    c.person_id
HAVING 
    COUNT(DISTINCT ca.movie_id) > 10;  -- Only include persons with more than 10 movies

-- String manipulation example
SELECT 
    id, 
    CONCAT('Movie: ', title, ' - Year: ', production_year) AS movie_description
FROM 
    aka_title
WHERE 
    production_year BETWEEN 1990 AND 2000 
    AND title IS NOT NULL
ORDER BY 
    production_year DESC;

-- Combine with NULL checks
SELECT 
    DISTINCT c.gender,
    COUNT(DISTINCT ca.movie_id) AS unique_movies
FROM 
    cast_info ca
LEFT JOIN 
    name c ON ca.person_id = c.id
WHERE 
    c.gender IS NOT NULL
GROUP BY 
    c.gender;
