WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL  -- Starting point: top-level movies (not episodes)

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title AS movie_title,
        et.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title et
    JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id  -- Recursive part to pull episodes
)

SELECT 
    m.movie_id,
    m.movie_title,
    m.production_year,
    COALESCE(a.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS num_info_details, -- Assuming info_type_id = 1 is some specific detail
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY m.production_year DESC) AS movie_rank
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year BETWEEN 2000 AND 2023  -- Filter for movies from this period
    AND (a.name IS NULL OR a.name NOT LIKE '%[0-9]%')  -- Exclude actors with numbers in the name
GROUP BY 
    m.movie_id, m.movie_title, m.production_year, a.name
HAVING 
    COUNT(DISTINCT ci.role_id) > 1  -- Only include movies with multiple roles
ORDER BY 
    movie_rank ASC;
