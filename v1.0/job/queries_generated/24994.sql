WITH RECURSIVE movie_hierarchy AS (
    -- CTE to establish a hierarchy of movies linked to each other.
    SELECT 
        ml.movie_id, 
        ml.linked_movie_id, 
        1 AS level
    FROM 
        movie_link ml 
    WHERE
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'SEQUEL')
    UNION ALL
    SELECT 
        mh.movie_id, 
        ml.linked_movie_id, 
        mh.level + 1 AS level
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ct.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    AVG(m.production_year) AS avg_production_year,
    COUNT(DISTINCT mh.linked_movie_id) AS sequels_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    MAX(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birth date') THEN pi.info END) AS birth_date,
    COUNT(*) FILTER (WHERE t.production_year IS NULL) AS null_production_year_count
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    movie_hierarchy mh ON t.id = mh.movie_id
WHERE 
    a.name IS NOT NULL 
    AND (mi.info IS NULL OR mi.note LIKE '%noteworthy%') -- Including bizarres on info
GROUP BY 
    a.name, t.title, ct.kind
HAVING 
    num_companies > 1 
    AND AVG(m.production_year) > 2000 
ORDER BY 
    sequels_count DESC, actor_name;

### Explanation of the Query Components:
1. **CTE (`WITH RECURSIVE movie_hierarchy`)**: This produces a recursive structure of sequels linking movies through `movie_link`, allowing us to count the number of sequels for each movie.

2. **Main SELECT Query**:
   - **Actor Name and Movie Title**: We fetch the actor’s name from `aka_name` and the title of the movie.
   - **Company Type**: We gather movie companies' types with an outer join on `movie_companies` and `company_type` tables.
   - **Count of Companies**: Count distinct companies associated with each movie.
   - **Average Production Year**: Average the production years (only movies after 2000).
   - **Count of Sequels**: Count the number of linked sequels derived from the CTE.
   - **Keyword Aggregation**: Aggregate movie keywords into a comma-separated string.
   - **Birth Date**: A correlated subquery to get the birth date of the actor (if it exists).
   - **NULL Logic**: Count movies with a null production year which adds ambiguity to the data.

3. **WHERE Clause**: Filtering for valid actor names and peculiar conditions on `movie_info`.

4. **GROUP BY and HAVING**: Aggregating the results based on actors and titles, and ensuring certain conditions are met (like having more than one company). The `HAVING` clause adds a nuance by enforcing logical criteria on aggregated columns.

5. **ORDER BY Clause**: Orders results first by the number of sequels in descending order and then by actor name, making results easier to analyze.

This query utilizes a variety of SQL features to demonstrate complexity while also handling potential edge cases in the dataset.
