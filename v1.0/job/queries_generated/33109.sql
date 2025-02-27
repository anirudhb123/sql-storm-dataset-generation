WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000  -- Only consider movies after 2000
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
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT c.id) AS cast_count,
    MAX(pi.info) FILTER (WHERE it.info = 'birth date') AS actor_birthdate,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY c.nr_order) AS role_order
FROM 
    movie_companies mc
LEFT JOIN 
    aka_title mt ON mc.movie_id = mt.id
INNER JOIN 
    cast_info c ON mt.id = c.movie_id
INNER JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    info_type it ON pi.info_type_id = it.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id -- Adding reference to recursive CTE
WHERE 
    a.name IS NOT NULL 
    AND mt.production_year IS NOT NULL
GROUP BY 
    a.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT c.id) > 1 -- Only include movies with more than one cast member
ORDER BY 
    mt.production_year DESC, actor_name;

This SQL query performs a sophisticated multi-table join using outer joins, inner joins, and various filtering options. It also uses a recursive common table expression (CTE) to manage a hierarchy of movies through their linked relationships. The query gathers information about actors, roles, related movies, and keywords, incorporating window functions and aggregation to produce a comprehensive view of actor participation in multiple films, while only selecting movies released after the year 2000.
