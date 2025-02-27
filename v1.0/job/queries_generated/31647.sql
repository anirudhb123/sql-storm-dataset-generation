WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL AS parent_movie_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT ckt.kind, ', ') AS company_types,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY at.production_year DESC) AS movie_rank
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = at.id
LEFT JOIN 
    company_type ckt ON mc.company_type_id = ckt.id
LEFT JOIN 
    movie_keyword mw ON mw.movie_id = at.id
LEFT JOIN 
    keyword kw ON mw.keyword_id = kw.id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
    AND at.production_year BETWEEN 2000 AND 2023
GROUP BY 
    ak.name, at.title, at.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    at.production_year DESC, ak.name;

In this SQL query, we are creating a recursive common table expression (CTE) called `MovieHierarchy` to traverse the hierarchy of movies linked to each other. We then select information about actors, their movies, and the companies involved in those movies. We use left joins to gather company types and keywords associated with each movie. We implement a filtering condition to consider only the movies produced between 2000 and 2023 and ensure the actor's name is not null or empty. 

We aggregate the results to count distinct companies, concatenate their types, and collect keywords associated with each movie. Lastly, we assign a ranking to each movie for each actor based on the production year in descending order. The output is sorted by production year and actor's name. This query incorporates various SQL features such as CTEs, aggregations, joins, window functions, and filters.
