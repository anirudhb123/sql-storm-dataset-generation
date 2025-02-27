WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    MAX(CASE WHEN m.kind_id IS NOT NULL THEN 'Has Production Company' ELSE 'No Production Company' END) AS company_status,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    RANK() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS role_rank
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_hierarchy mh ON t.id = mh.movie_id
WHERE 
    a.name IS NOT NULL AND 
    t.production_year IS NOT NULL AND 
    mh.level IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    t.production_year DESC, a.name;

This SQL query performs the following operations:
1. **Recursive CTE**: Constructs a hierarchy of movies starting from those produced since 2000.
2. **Joins**: Combines data from multiple tables (`cast_info`, `aka_name`, `title`, `movie_companies`, `movie_keyword`, and `keyword`).
3. **Aggregation**: Counts distinct companies, aggregates keywords, and ranks roles by order.
4. **Conditional Logic**: Uses a CASE statement to derive the production company presence status.
5. **Filtering**: Excludes records where the actor name or production year is NULL and limits to movies with more than one associated company.
6. **Ordering**: Outputs results sorted by production year and actor name.

This query is complex and made for performance benchmarking while showcasing various SQL constructs.
