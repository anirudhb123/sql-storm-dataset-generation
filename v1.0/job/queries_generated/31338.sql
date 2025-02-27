WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        1 AS level,
        CAST(t.title AS VARCHAR(255)) AS path
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        mt.linked_movie_id AS movie_id,
        lt.title AS movie_title,
        lt.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || lt.title AS VARCHAR(255))
    FROM 
        movie_link mt
    JOIN 
        title lt ON lt.id = mt.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = mt.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.level,
    mh.path,
    COALESCE(COUNT(CAST(ci.person_id AS INTEGER)), 0) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS key_actors,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    ROUND(AVG(mi.info_type_id), 2) AS avg_info_type_id
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id
WHERE 
    mh.production_year IS NOT NULL
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, mh.level, mh.path
HAVING 
    CAST(AVG(mh.level) AS INTEGER) > 1
ORDER BY 
    mh.production_year DESC, cast_count DESC;


In this SQL query:
- A recursive Common Table Expression (CTE) called `MovieHierarchy` builds a hierarchy of movies based on related links.
- Outer joins are used to ensure that even movies without casts or keywords are included.
- Aggregate functions like `COUNT`, `STRING_AGG`, and `AVG` are utilized to summarize data across the hierarchy.
- The `HAVING` clause filters out entries based on the average level, ensuring that only those deeper in the hierarchy are selected.
- The results are ordered by production year and cast count to make it easier to analyze the results based on recent popular films and their respective casts.
