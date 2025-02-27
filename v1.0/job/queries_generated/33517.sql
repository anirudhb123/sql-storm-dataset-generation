WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000  -- Filter for movies after year 2000

    UNION ALL

    SELECT 
        mv.id,
        mv.title,
        mv.production_year,
        mh.level + 1,
        mv.episode_of_id
    FROM 
        aka_title mv
    INNER JOIN 
        MovieHierarchy mh ON mv.episode_of_id = mh.id
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    ak.name AS actor_name,
    r.role AS actor_role,
    COALESCE(mn.keyword, 'No Keyword') AS keyword, -- Handle NULL for keywords
    COUNT(DISTINCT mv.linked_movie_id) AS linked_movies,
    AVG(CASE WHEN ai.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY ak.name) AS has_notes,
    STRING_AGG(DISTINCT ci.note, ', ') AS cast_notes
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info ci ON m.id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword mn ON mk.keyword_id = mn.id
LEFT JOIN 
    movie_link mv ON m.id = mv.movie_id
GROUP BY 
    m.title, m.production_year, ak.name, r.role
HAVING 
    COUNT(DISTINCT ci.person_id) > 5  -- Only include movies with more than 5 unique cast members
ORDER BY 
    m.production_year DESC, 
    COUNT(DISTINCT mv.linked_movie_id) DESC;

This SQL query demonstrates a complex use of recursive Common Table Expressions (CTEs) to create a hierarchy of movies, containing episodes and their parent series. The query includes multiple JOINs, aggregates, and conditions including filtering NULL values, calculating averages with window functions, and concatenating strings from associated tables while applying GROUP BY and HAVING clauses. The ordering criteria prioritize more recent movies with substantial cast sizes and preserved movie relationships.
