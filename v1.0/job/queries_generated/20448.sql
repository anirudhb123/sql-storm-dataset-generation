WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CAST(ARRAY[mt.id] AS INTEGER[]) AS hierarchy
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        h.hierarchy || ml.linked_movie_id
    FROM 
        MovieHierarchy h
    JOIN 
        movie_link ml ON h.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT mt.company_id) AS company_count,
    ARRAY_AGG(DISTINCT k.keyword) FILTER (WHERE k.keyword IS NOT NULL) AS associated_keywords,
    ROW_NUMBER() OVER(PARTITION BY a.name ORDER BY t.production_year DESC) AS rank,
    COALESCE(mk.genre, 'N/A') AS genre
FROM 
    aka_name a
INNER JOIN 
    cast_info c ON a.person_id = c.person_id
INNER JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
INNER JOIN 
    aka_title t ON mh.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    keyword k ON t.id = k.id
LEFT JOIN (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT mkt.kind, ', ') AS genre
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        kind_type mkt ON k.id = mkt.id
    GROUP BY 
        mk.movie_id
) mk ON t.id = mk.movie_id
GROUP BY 
    a.name, t.title, t.production_year, genre
HAVING 
    COUNT(DISTINCT mc.company_id) > 0 AND 
    COUNT(DISTINCT k.keyword) > 2
ORDER BY 
    t.production_year DESC, rank;

### Explanation:
- **CTE (Common Table Expression)**: `MovieHierarchy` recursively builds a hierarchy of movies connected through links to provide a comprehensive view of movie relations.
- **Joins**: The query uses multiple joins to combine data across different entities, such as actors, movies, keywords, and company associations.
- **Filters and Aggregates**: It aggregates both keywords and company counts while filtering out records that do not meet the criteria.
- **Window Function**: `ROW_NUMBER()` is employed to rank movies for each actor by production year.
- **NULL Logic & COALESCE**: The query intelligently handles potential NULL values for genres with `COALESCE`, ensuring a response even if no genres are found.
- **HAVING Clause**: Additional filtering is done to only return actors with a certain level of association to companies and keywords, demonstrating complex predicates.
- **Array Handling**: Uses `ARRAY_AGG` to collate any number of associated keywords while ensuring distinctness.

The above SQL query serves as an interesting benchmark due to its complexity and depth of SQL features while navigating through the relationships in the `Join Order Benchmark` schema.
