WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year >= 2000  -- Base case: movies from the year 2000 onwards

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id 
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    AKA.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(CASE WHEN mh.production_year < 2020 THEN 1 ELSE NULL END) AS avg_movies_pre_2020,
    STRING_AGG(DISTINCT mt.title, ', ') AS linked_titles,
    COALESCE(ct.kind, 'Unknown') AS company_type
FROM 
    cast_info ci
JOIN 
    aka_name AKA ON ci.person_id = AKA.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    AKA.name IS NOT NULL 
    AND mh.level <= 2  -- Limiting to direct and one level of linked movies
GROUP BY 
    AKA.name, ct.kind
HAVING 
    COUNT(DISTINCT mh.movie_id) >= 3  -- Only select actors in at least 3 movies
ORDER BY 
    total_movies DESC, actor_name;

This SQL query uses a recursive CTE to build a movie hierarchy starting from movies produced in or after the year 2000. It joins several tables to gather data about actors, their linked films, and the companies responsible for those films. It includes aggregates and filters conditions to provide valuable information regarding actors who have had substantial participation in films along with their associated company types. The results are grouped by actor and the type of company, ensuring we only return actors associated with a minimum number of films.
