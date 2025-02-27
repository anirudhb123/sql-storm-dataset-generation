WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
)
SELECT 
    DISTINCT ak.name AS actor_name,
    mt.title,
    mt.production_year,
    COUNT(DISTINCT mc.company_id) AS production_companies_count,
    SUM(CASE WHEN mp.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') THEN mp.info::FLOAT ELSE 0 END) AS total_budget
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    movie_info mp ON mt.id = mp.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND mt.production_year >= 2000
    AND (mt.title ILIKE '%adventure%' OR mt.title ILIKE '%fantasy%')
GROUP BY 
    ak.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 2 
ORDER BY 
    total_budget DESC;

WITH ActorMovieCounts AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ak.name
)
SELECT 
    amc.actor_name,
    amc.movie_count,
    COALESCE(mh.num_movies, 0) AS movies_in_hierarchy
FROM 
    ActorMovieCounts amc
LEFT JOIN 
    (SELECT 
         actor_name, 
         COUNT(*) AS num_movies
     FROM 
         MovieHierarchy
     JOIN 
         cast_info ci ON MovieHierarchy.movie_id = ci.movie_id
     JOIN 
         aka_name ak ON ci.person_id = ak.person_id
     GROUP BY 
         actor_name) mh ON amc.actor_name = mh.actor_name
ORDER BY 
    amc.movie_count DESC;


The SQL scripts above constructs a complex performance benchmarking query that leverages multiple advanced SQL elements:

1. **Recursive Common Table Expression (CTE)** `MovieHierarchy` - This is used to build a hierarchy of movies linking related titles.
2. **Multiple JOINs** - The queries perform `JOINs` across multiple tables, including `aka_name`, `aka_title`, and `movie_companies`, showcasing complex relationships.
3. **Aggregations** - `COUNT` and `SUM` functions are used to calculate distinct counts of production companies and total budget information.
4. **Group By and Having Clauses** - These are applied to group results based on actor names and titles, and to filter results based on specific criteria.
5. **COALESCE function** - Used for handling NULL values in the results.
6. **WHERE clause predicates** - Include filtering based on production year and matching string patterns.

The script should provide a detailed insight into the actors' involvement in movie productions with consideration for certain criteria that would be useful in benchmarks.
