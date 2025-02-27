WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title linked ON linked.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = m.id
)
SELECT
    mv.title,
    mv.production_year,
    COUNT(DISTINCT cc.person_id) AS num_cast,
    AVG(case when ci.nr_order IS NOT NULL then ci.nr_order else 0 end) AS avg_order,
    STRING_AGG(DISTINCT ak.name, ', ') FILTER (WHERE ak.name IS NOT NULL) AS aka_names,
    string_agg(DISTINCT kn.keyword, ', ') AS keywords,
    p.gender,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = mv.movie_id) AS num_companies
FROM 
    movie_hierarchy mv
LEFT JOIN 
    cast_info ci ON ci.movie_id = mv.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mv.movie_id
LEFT JOIN 
    keyword kn ON kn.id = mk.keyword_id
LEFT JOIN 
    person_info pi ON pi.person_id = ci.person_id
LEFT JOIN 
    name p ON p.id = pi.person_id
WHERE 
    mv.level = 1
GROUP BY 
    mv.title, mv.production_year, p.gender
HAVING 
    COUNT(DISTINCT cc.person_id) > 5
    AND AVG(case when ci.nr_order IS NOT NULL then ci.nr_order else 0 end) > 0
ORDER BY 
    mv.production_year DESC, num_cast DESC
LIMIT 100;

### Query Explanation:

1. **Common Table Expression (CTE):** 
   - The `RECURSIVE movie_hierarchy` CTE builds a hierarchy of movies starting from those produced from the year 2000 onwards.
   - It iteratively finds linked movies using the `movie_link` table.

2. **Main Query:**
   - It selects relevant data from the `movie_hierarchy` and aggregates it with multiple `LEFT JOIN` operations.
   - The `COUNT` function calculates the number of distinct cast members for each movie.
   - The `AVG` function calculates the average cast order.
   - `STRING_AGG` is used for concatenating actor names and movie keywords, demonstrating use of string expressions and NULL handling.

3. **Filtering Conditions:**
   - The query uses a `HAVING` clause to ensure that movies have more than 5 unique cast members and that their average order is greater than 0.

4. **Ordering and Limiting Results:**
   - The results are ordered by the production year (most recent first) and the number of cast members, ensuring the most populated movies appear first. 
   - Finally, only the top 100 results are returned, providing a performance benchmarking output indicating the complexity inherent in the joins and aggregations.
