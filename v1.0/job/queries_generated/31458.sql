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
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY at.production_year DESC) AS rank,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = at.id) AS total_cast,
    STRING_AGG(DISTINCT kn.keyword, ', ') FILTER (WHERE kn.keyword IS NOT NULL) AS keywords
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
) kn ON at.id = kn.movie_id
WHERE 
    at.production_year >= 2000
GROUP BY 
    ak.name, at.title, at.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    rank, at.production_year DESC;

### Explanation of Query Components:

1. **Recursive CTE (MovieHierarchy)**: This allows the exploration of linked movies creating a hierarchy of movies, which can later be expanded upon for deeper queries.

2. **Main SELECT Statement**: This combines various tables:
   - **aka_name as ak**: Retrieves the actor names.
   - **cast_info as ci**: Joins with actor information to get movie relationships.
   - **aka_title as at**: Provides movie details.
   - **movie_companies as mc**: Captures companies associated with the movies.

3. **Window Function (ROW_NUMBER)**: Ranks movies for each actor by production year, allowing the resulting dataset to indicate the most recent works of each actor.

4. **Subquery**: This counts total cast members for each movie and collects keywords related to each movie.

5. **String Aggregation (STRING_AGG)**: Concatenates keywords associated with the movies but filters out NULL values.

6. **HAVING Clause**: Ensures that only movies associated with at least one company are listed.

7. **Filtering (WHERE)**: Limits results to movies produced in or after the year 2000. 

This SQL statement will benchmark performance across multiple joins, subqueries, and aggregate functions while displaying interesting metrics about actors, films, and their corporate connections.
