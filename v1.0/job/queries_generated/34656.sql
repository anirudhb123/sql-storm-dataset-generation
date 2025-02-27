WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.id
)
SELECT 
    ma.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(mk.keyword) AS keyword_count,
    AVG(mi.info::FLOAT) AS average_rating,
    ROW_NUMBER() OVER (PARTITION BY ma.name ORDER BY mt.production_year DESC) AS recent_movie_rank,
    COALESCE(STRING_AGG(DISTINCT mk.keyword, ', '), 'No keywords') AS keywords,
    CASE 
        WHEN COUNT(mk.keyword) > 0 THEN 'Has keywords' 
        ELSE 'No keywords' 
    END AS keyword_status
FROM 
    aka_name ma
JOIN 
    cast_info ci ON ma.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id = (
        SELECT 
            id FROM info_type WHERE info = 'rating'
    )
LEFT JOIN 
    movie_hierarchy mh ON mt.id = mh.movie_id
GROUP BY 
    ma.name, mt.id
HAVING 
    COUNT(CASE WHEN mk.keyword IS NULL THEN 1 END) < 5
ORDER BY 
    recent_movie_rank;

In this SQL query, several advanced constructs are utilized. Here’s a breakdown of the components used:

1. **Recursive CTE**: The `movie_hierarchy` CTE allows for navigating hierarchical movie links (linked movies), recursively building a movie tree.

2. **Joins**: Different join types are employed, including inner joins (`JOIN`) for mandatory relationships and left joins (`LEFT JOIN`) to include optional data like keywords and ratings.

3. **Window Functions**: The `ROW_NUMBER()` function assigns a rank to movies per actor based on the most recent production year.

4. **Aggregation**: The query counts the distinct keywords associated with each movie, averages ratings, and groups results by actor and movie title.

5. **Conditional Logic**: The `CASE` statement evaluates whether or not there are keywords present and helps to create a status label.

6. **NULL Handling**: It uses `COALESCE` to ensure that if there are no keywords, a fallback message is provided.

7. **String Aggregation**: `STRING_AGG` is used to concatenate keywords into a single string (if any). 

8. **HAVING Clause**: It filters results based on condition by counting NULL occurrences of keywords.

This query is both comprehensive and complex, providing extensive data insights while showcasing the potential for advanced SQL techniques.
