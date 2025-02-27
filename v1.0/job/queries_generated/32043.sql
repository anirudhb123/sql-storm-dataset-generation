WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
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
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.movie_title,
    YEAR(mh.production_year) AS movie_year,
    COUNT(DISTINCT ci.id) AS role_count,
    AVG(REGEXP_REPLACE(mk.keyword, '[^a-zA-Z]', '')::TEXT) AS average_keywords_length,
    ARRAY_AGG(DISTINCT ci.note) AS role_notes
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    ak.name IS NOT NULL
    AND mh.level <= 2
GROUP BY 
    ak.name, mt.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.id) > 1
ORDER BY 
    movie_year DESC, ak.actor_name ASC;

Explanation:
1. This query creates a recursive Common Table Expression (CTE) called `MovieHierarchy` to build a hierarchy of movies linked together (through the `movie_link` table).
2. It starts by selecting movies from the `aka_title` table produced after the year 2000.
3. The UNION ALL allows it to retrieve linked movies recursively.
4. The main SELECT statement aggregates information about actors, their roles, and associated keywords.
5. It includes multiple join conditions and applies a LEFT JOIN to get movie titles.
6. An array aggregate collects notes from `cast_info` for the actor’s roles.
7. A filtering clause (HAVING) ensures that only actors with more than one role are included.
8. Finally, it orders the results by release year and actor name.
