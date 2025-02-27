WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1 AS depth,
        CAST(mh.path || ' > ' || at.title AS VARCHAR(255)) AS path
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3   -- Limit to three levels deep
)

SELECT 
    p.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    MAX(mh.path) AS movie_path,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(years.produced_years) AS average_produced_years
FROM 
    cast_info c
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN (
    SELECT 
        movie_id,
        EXTRACT(YEAR FROM CURRENT_DATE) - production_year AS produced_years
    FROM 
        aka_title
) years ON years.movie_id = c.movie_id
WHERE 
    p.name IS NOT NULL
GROUP BY 
    p.name
ORDER BY 
    movie_count DESC
LIMIT 10;

This query accomplishes the following:
1. It creates a recursive CTE that retrieves a hierarchy of movies linked to those produced in or after the year 2000, up to three levels deep.
2. It collects the actor names and counts distinct movies they appeared in, while also constructing paths showing their related movies.
3. It aggregates keywords associated with each movie and calculates the average number of years after production for those movies.
4. It includes a mix of necessary joins across an elaborate set of tables with filtering for non-null names, ordering results for the top 10 actors based on the number of movies they featured in.
