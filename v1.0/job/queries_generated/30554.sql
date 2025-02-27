WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ah.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    ARRAY_AGG(DISTINCT cct.kind) AS company_types,
    STRING_AGG(DISTINCT ci.note, '; ') AS notes,
    MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') THEN mi.info END) AS budget,
    SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS cast_count,
    ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS rank
FROM 
    movie_companies AS mc
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    aka_title AS mt ON mc.movie_id = mt.id
LEFT JOIN 
    cast_info AS ci ON mt.id = ci.movie_id
LEFT JOIN 
    aka_name AS ah ON ci.person_id = ah.person_id
LEFT JOIN 
    movie_keyword AS mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword AS kc ON mk.keyword_id = kc.id
LEFT JOIN 
    comp_cast_type AS cct ON ci.person_role_id = cct.id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id
WHERE 
    mt.production_year IS NOT NULL
GROUP BY 
    ah.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT kc.keyword) > 0
ORDER BY 
    production_year, keyword_count DESC;

### Explanation:
1. **CTE (Common Table Expression)**: The query includes a recursive CTE (`movie_hierarchy`) that builds a hierarchy of movies based on linked relationships which allows capturing sequels or related films.
2. **Joins**: Multiple outer and inner joins gather data from many tables including actors, movies, company information, and keywords.
3. **Aggregations**: The query computes counts of distinct keywords and aggregates company types and notes, providing rich information in a single query.
4. **Null Logic**: The query uses `LEFT JOIN` and conditional aggregation to handle NULL values appropriately.
5. **Rank and Window Functions**: Finally, a `ROW_NUMBER` function ranks movies by the number of keywords per year, adding a competitive perspective to the result set.
6. **Complex Conditions**: The `HAVING` clause ensures that only movies with keywords are included, enhancing dataset relevance. 

The structure is designed to give deep insights into movie data and actor contributions while remaining efficient for performance benchmarking.
