WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Starting with movies after the year 2000
    
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
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY mh.production_year DESC) AS actor_rank,
    CASE 
        WHEN mh.level > 1 THEN 'Sequels/Prequels'
        ELSE 'Stand-alone'
    END AS movie_relationship_type,
    COALESCE(mn.info, 'No additional info available') AS additional_info
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mn ON mh.movie_id = mn.movie_id AND mn.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis' LIMIT 1)
WHERE 
    ci.note IS NULL  -- Only considering entries without additional notes
GROUP BY 
    ak.name, mt.title, mh.production_year, mn.info
HAVING 
    COUNT(DISTINCT mc.company_id) > 1  -- Only include movies with more than one production company
ORDER BY 
    actor_rank, production_year DESC;

This query achieves several objectives and demonstrates various SQL constructs:
- A recursive common table expression (CTE) builds a hierarchy of movies with a production year after 2000, linking sequels and prequels.
- It aggregates keywords related to the movies and counts distinct production companies.
- It uses window functions to rank actors based on their most recent movie, and applies string aggregation to form a list of keywords.
- The `CASE` statement differentiates between stand-alone films and sequels/prequels.
- It incorporates left joins to fetch additional information like movie synopses, ensuring null handling with `COALESCE`.
- The `HAVING` clause filters results based on company counts, and results are ordered to prioritize higher-ranked actors.
