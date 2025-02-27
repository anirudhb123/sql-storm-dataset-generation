WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

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
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3  -- Max depth of the hierarchy
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY at.production_year DESC) AS movie_rank,
    COALESCE(mk.keyword, 'No keyword') AS movie_keyword,
    COUNT(DISTINCT mc.company_id) OVER (PARTITION BY at.id) AS num_companies
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
WHERE 
    ak.name IS NOT NULL
    AND at.production_year BETWEEN 2000 AND 2023
    AND EXISTS (
        SELECT 1
        FROM complete_cast cc
        WHERE cc.movie_id = at.id
        AND cc.subject_id = ak.id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = at.id
        AND mi.info_type_id IN (
            SELECT id FROM info_type WHERE info = 'Banned'    -- Filter for non-banned movies
        )
    )
ORDER BY 
    ak.actor_name, at.production_year DESC;

This SQL query contains several complex elements designed for performance benchmarking against the provided schema:

1. **Recursive CTE**: The `movie_hierarchy` CTE gathers movies starting in 2000 and explores linked movies up to three levels deep.

2. **Window Functions**: The `ROW_NUMBER()` function ranks movies per actor based on the production year.

3. **JOINs**: The query includes inner and outer joins to relate actors, movies, keywords, and companies.

4. **Correlated Subqueries**: Subqueries check for the existence of relationships in the `complete_cast` and verify non-banned movies via the `movie_info` table.

5. **Complicated Predicates**: Use of `COALESCE` handles potential NULL values for keywords.

6. **String Handling**: The query ensures that only non-null actor names are considered, and incorporates filtering criteria.

The full expressiveness of SQL capabilities is showcased, which is suitable for assessing performance while ensuring comprehensive data retrieval.
