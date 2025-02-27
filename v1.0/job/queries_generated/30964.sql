WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Start with movies from the year 2000 onwards

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3  -- Limit the recursion to 2 levels deep
)

SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    COALESCE(c.name, 'Unknown') AS company_name,
    COUNT(DISTINCT mi.info_type_id) AS info_count,
    COUNT(DISTINCT ka.id) AS actor_count,
    RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ka.id) DESC) AS actor_rank,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    CASE 
        WHEN COUNT(DISTINCT ka.id) = 0 THEN 'No actors'
        ELSE 'Has actors'
    END AS actor_presence
FROM 
    MovieHierarchy mh
JOIN 
    aka_title m ON mh.movie_id = m.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id
LEFT JOIN 
    cast_info ci ON m.id = ci.movie_id
LEFT JOIN 
    aka_name ka ON ci.person_id = ka.person_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    m.id, m.title, m.production_year, c.name
HAVING 
    COUNT(DISTINCT ka.id) > 0  -- Only include movies with actors
ORDER BY 
    m.production_year DESC, actor_count DESC;

This SQL query achieves several objectives, including:

- Recursive Common Table Expressions (CTE) to create a movie hierarchy, allowing exploration of linked movies up to two levels deep.
- Aggregation functions such as `COUNT` and `STRING_AGG` to calculate the number of actors and gather keywords, respectively.
- Usage of `LEFT JOIN` to include optional company and keyword information, while handling possible NULL values.
- Ranking movies per production year by the number of distinct actors using the `RANK()` window function.
- A condition in the `HAVING` clause to exclude movies without actors. 
- A COALESCE function to provide a default value for company names classified as "Unknown".
