WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL

    UNION ALL

    SELECT 
        c.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON ah.person_id = c.person_id
    WHERE 
        ah.level < 5  -- Limit recursion to avoid infinite loops
)
SELECT 
    a.actor_name,
    ARRAY_AGG(DISTINCT t.title) AS titles,
    COUNT(DISTINCT t.id) AS total_titles,
    SUM(CASE WHEN t.production_year IS NOT NULL THEN 1 ELSE 0 END) AS produced_years,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COALESCE(NULLIF(SUM(CASE WHEN c.natural_order IS NOT NULL THEN c.natural_order ELSE 0 END), 0), 'No Order') AS role_order,
    AVG(t.production_year) AS avg_production_year
FROM 
    ActorHierarchy a
LEFT JOIN 
    cast_info ci ON ci.person_id = a.person_id
LEFT JOIN 
    aka_title t ON t.id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND (t.note IS NULL OR t.note NOT LIKE '%unreleased%')
GROUP BY 
    a.actor_name
HAVING 
    COUNT(DISTINCT t.id) > 5 
ORDER BY 
    avg_production_year DESC,
    total_titles DESC
LIMIT 10 OFFSET 0;

### Explanation of the Query:
1. **CTE (Common Table Expression)** - `ActorHierarchy`: This recursively builds a hierarchy of actors based on their participation in movies. It limits the recursion to a maximum of 5 levels deep.
  
2. **Main SELECT**: This gathers data about the actors including:
   - Their names.
   - An aggregated list of movie titles they participated in (using `ARRAY_AGG`).
   - The total count of titles they have acted in.
   - A count of non-null production years, handled to ensure that NULL values are not counted.
   - A concatenated string of associated keywords (if any).
   - A conditional aggregation for the `natural_order` from the `cast_info` table which defaults to 'No Order' if all are NULL.
   - The average production year for the movies they participated in.

3. **Joins**:
   - Multiple outer joins are used to include as much relevant data as possible without forcing an exclusion of results based on missing data.
   
4. **WHERE Clause**: This filters results to movies produced from 2000 onwards and excludes unreleased movies based on note content.

5. **HAVING Clause**: This ensures that only actors with more than 5 titles are included in the result.

6. **Order By**: Results are ordered by average production year descending and total titles descending.

7. **LIMIT and OFFSET**: Implement pagination by limiting results to 10 actors while skipping the first 0 (no skip). 

This combination of features creates a complex query for benchmarking SQL performance focusing on a rich dataset with various conditions and aggregations.
