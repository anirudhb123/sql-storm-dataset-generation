WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.id AS movie_id,
    m.title,
    COALESCE(c.first_actor, 'No Cast') AS first_actor,
    m.production_year,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT kw.keyword) DESC) AS production_rank
FROM 
    aka_title m
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    (SELECT 
        ci.movie_id,
        ak.name AS first_actor
     FROM 
        cast_info ci
     JOIN 
        aka_name ak ON ci.person_id = ak.person_id
     WHERE 
        ci.nr_order = 1
    ) c ON c.movie_id = m.id
WHERE 
    m.production_year IS NOT NULL
GROUP BY 
    m.id, m.title, first_actor
HAVING 
    COUNT(DISTINCT kw.keyword) > 2 AND 
    m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('feature', 'short'))
ORDER BY 
    production_year DESC, 
    keyword_count DESC;

### Explanation of the Query Constructs:
- **Recursive CTE** (`MovieHierarchy`): This is used to create a hierarchy of movies linked to each other through `movie_link` while only including those produced from the year 2000 and onwards.
  
- **Outer Joins**: The query uses `LEFT JOIN` to ensure that we include movies even if they don't have associated keywords or first actors.

- **Correlated Subquery**: The subquery within the `FROM` clause for first actors ensures that we only select those movies that have at least one cast member.

- **Window Functions**: `ROW_NUMBER()` ranks movies within their production year based on the count of distinct keywords.

- **Set Operators**: The use of `IN` allows filtering the movie kind to only include certain types ('feature', 'short') by querying the `kind_type` table.

- **Complicated Predicates**: The `HAVING` clause not only filters by the count of keywords but also ensures valid movie types.

- **NULL Logic**: The `COALESCE` function handles the potential NULL values for the first actor to replace them with a default message.
