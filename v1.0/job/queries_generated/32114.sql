WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL 

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT c.person_role_id) AS role_count,
    RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_role_id) DESC) AS role_rank,
    COALESCE(MAX(mci.note), 'No company association') AS company_note
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    c.nr_order = 1 
    AND (k.keyword IS NOT NULL OR t.production_year IS NOT NULL)
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT c.person_role_id) > 1
ORDER BY 
    t.production_year DESC, role_count DESC;

This SQL query performs the following actions:

1. It defines a recursive Common Table Expression (CTE) `movie_hierarchy` to explore movie relationships within the production years starting from 2000.
2. It selects actor names from `aka_name`, along with associated movie titles and production years, counting unique roles and aggregating the keywords associated with the movies.
3. It employs a `LEFT JOIN` to include company information, with a COALESCE function to handle potential NULL values seamlessly.
4. The query uses `RANK()` window function to rank movies per production year based on the number of roles.
5. There’s filtering to include only those roles with a specific order (`c.nr_order = 1`) and includes conditions to ensure either keyword or production year is not NULL.
6. The final output is grouped by actor name, movie title, and production year, with a condition to ensure there are significant roles (`HAVING COUNT(DISTINCT c.person_role_id) > 1`).

This query efficiently combines several SQL constructs for complex data analysis.
