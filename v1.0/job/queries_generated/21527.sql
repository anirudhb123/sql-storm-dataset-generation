WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        ml.linked_movie_id,
        1 AS level
    FROM 
        title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    WHERE 
        ml.linked_movie_id IS NOT NULL

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.movie_title,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
)

SELECT 
    t.id AS title_id,
    t.title AS title,
    COALESCE(a.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_present_count,
    DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS actor_rank,
    -- Check for potential NULLs in names and productions
    COUNT(mh.linked_movie_id) FILTER (WHERE mh.linked_movie_id IS NOT NULL) AS linked_movie_count,
    CASE 
        WHEN COUNT(mh.linked_movie_id) = 0 THEN 'No Links'
        WHEN COUNT(mh.linked_movie_id) < 3 THEN 'Few Links'
        ELSE 'Many Links'
    END AS link_category
FROM 
    title t
LEFT JOIN 
    cast_info ci ON t.id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_hierarchy mh ON t.id = mh.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND (a.name IS NOT NULL OR t.title IS NOT NULL)
GROUP BY 
    t.id, t.title, a.name
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    actor_rank, company_count DESC;

### Explanation:
1. **CTE `movie_hierarchy`:** This recursive CTE gathers linked movies, allowing us to explore movie relationships up to any depth.
  
2. **Main Query:**
    - Joins various tables to gather relevant details of movies, actors, companies, and keywords. 
    - Uses conditional logic to manage NULLs and counts.
    - String aggregation for keywords associated with the titles.
    - DENSE_RANK is applied partition-wise to rank movies by the number of distinct actors per production year.
    - Conditional counting and category assignment for linked movies.

3. **Filtering Logic:** The query limits results to movies produced between 2000 and 2023, ensuring relevance to modern datasets while managing NULL cases effectively.

4. **HAVING Clause:** Ensures that only titles associated with at least one actor are included in the result. 

5. **ORDER BY Clause:** Sorts final results first by actor rank and then by the number of associated companies, reflecting both the quality and quantity of movie collaborations.
