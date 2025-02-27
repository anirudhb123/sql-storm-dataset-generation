WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level,
        CAST(mt.title AS TEXT) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        mh.level + 1 AS level,
        CAST(mh.path || ' -> ' || at.title AS TEXT)
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mh.movie_title,
    mh.level,
    mh.path,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    mh.level <= 5  -- Limit the depth of the hierarchy
GROUP BY 
    mh.movie_id, mh.movie_title, mh.level, mh.path
HAVING 
    COUNT(DISTINCT ci.person_id) > 0  -- Only include movies with a cast
ORDER BY 
    mh.level DESC, 
    CAST(mh.movie_title AS TEXT)
LIMIT 50;

-- Benchmarking Related
SELECT 
    name,
    COUNT(*) AS total_movies,
    AVG(production_year) AS average_production_year,
    MAX(production_year) AS latest_movie_year
FROM 
    aka_name an
JOIN 
    cast_info ci ON an.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
GROUP BY 
    an.name
HAVING 
    COUNT(*) > 5  -- Only consider persons with more than 5 movies
ORDER BY 
    total_movies DESC
LIMIT 100;

-- Complex nested query example
SELECT 
    c.name AS company_name,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY mt.production_year) AS median_production_year
FROM 
    company_name c
JOIN 
    movie_companies mc ON c.id = mc.company_id
JOIN 
    aka_title mt ON mc.movie_id = mt.id
GROUP BY 
    c.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 3  -- Companies with more than 3 movies
ORDER BY 
    total_movies DESC;

-- Using a window function to get rankings
WITH RankedTitles AS (
    SELECT 
        at.id,
        at.title,
        DENSE_RANK() OVER (ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        at.id, at.title
)
SELECT 
    rt.title,
    rt.rank
FROM 
    RankedTitles rt
WHERE 
    rt.rank <= 10;  -- Top 10 movies based on cast size
