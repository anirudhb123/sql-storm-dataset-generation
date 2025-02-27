WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        0 AS level
    FROM 
        title
    WHERE 
        title.id IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mk.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        movie_link mk
    JOIN 
        title t ON mk.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY actor_count DESC) AS rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 0 AND
    mh.production_year BETWEEN 2000 AND 2020
ORDER BY 
    mh.production_year DESC, actor_count DESC;

This SQL query constructs a recursive common table expression (CTE) to build a hierarchy of movies based on linked connections. It aggregates actor information, counts actors and notes for movies, while also using window functions for ranking. It ensures to filter movies only between 2000 and 2020 and retrieves a list of actor names associated with each movie. The query combines outer joins, aggregates, and conditional logic to provide a comprehensive result set for performance benchmarking.
