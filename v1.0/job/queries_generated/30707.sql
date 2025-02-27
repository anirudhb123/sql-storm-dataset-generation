WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        mt.kind_id, 
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  -- starting point for hierarchy, top-level movies

    UNION ALL

    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        mt.kind_id, 
        mh.depth + 1
    FROM 
        aka_title mt
    INNER JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id  -- recursive join for episodes
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    MAX(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS has_female_actor,
    SUM(CASE WHEN mi.info_type_id = 1 AND mi.info IS NOT NULL THEN 1 ELSE 0 END) AS total_movie_info,
    COUNT(DISTINCT mk.keyword_id) AS total_keywords,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS production_year_rank
FROM 
    movie_hierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 2  -- filter for movies with more than 2 cast members
ORDER BY 
    m.production_year DESC, total_cast DESC;

This SQL query does the following:

1. **Recursive CTE**: It builds a hierarchy of movies and episodes using a recursive common table expression (`movie_hierarchy`).
2. **Joins**: It performs multiple outer joins to gather data from related tables such as `complete_cast`, `cast_info`, `aka_name`, `movie_info`, and `movie_keyword`.
3. **Aggregations**: It counts distinct actors, aggregates their names, checks for female actors, sums movie information entries, and counts keywords.
4. **Window Function**: `ROW_NUMBER()` is used to rank movies within each production year.
5. **Filtering**: A `HAVING` clause ensures only movies with more than 2 cast members are included in the results.
6. **Ordering**: Finally, it orders the results by `production_year` and `total_cast`.

This query can serve as a comprehensive benchmark of table joins and aggregate functions in SQL.
