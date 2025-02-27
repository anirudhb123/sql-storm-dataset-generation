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
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year AS release_year,
    COUNT(DISTINCT c.person_id) OVER (PARTITION BY mt.id) AS actor_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') FILTER (WHERE kw.keyword IS NOT NULL) AS keywords,
    COUNT(cm.company_id) AS production_companies,
    AVG(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) END) AS avg_info_length,
    CASE 
        WHEN mt.production_year < 2010 THEN 'Older' 
        ELSE 'Newer' 
    END AS movie_age_group
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title mt ON c.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    company_name cm ON mc.company_id = cm.id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, mt.id, mt.title, mt.production_year
ORDER BY 
    release_year DESC, actor_name;

This SQL query explores a movie database by retrieving information about actors, their movies, production companies, and associated keywords. It includes a recursive CTE to handle movie relationships, aggregates data for actor counts and keywords, and evaluates the average length of information related to movies—all while applying NULL logic and string expressions. Ordering and filtering conditions make it useful for performance benchmarking in a diverse context.
