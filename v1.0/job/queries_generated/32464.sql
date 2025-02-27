WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        id AS movie_id,
        title,
        production_year,
        1 AS level
    FROM 
        aka_title 
    WHERE 
        kind_id = 1 -- assuming '1' is for movies
    
    UNION ALL
    
    SELECT 
        mt.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    COALESCE(kt.keyword, 'No Keyword') AS movie_keyword,
    COUNT(DISTINCT mc.movie_id) AS related_movies_count,
    AVG(mr.level) AS average_hierarchy_level,
    STRING_AGG(DISTINCT CONCAT(a.name, ' as ', r.role)) AS cast_names
FROM 
    MovieHierarchy mr
LEFT JOIN 
    movie_keyword mk ON mr.movie_id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
LEFT JOIN 
    complete_cast cc ON mr.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id 
LEFT JOIN 
    role_type r ON ci.role_id = r.id 
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON mr.movie_id = mc.movie_id
WHERE 
    mr.production_year >= 2000 
    AND (mc.note IS NULL OR mc.note != 'Uncredited')
GROUP BY 
    kt.keyword
ORDER BY 
    2 DESC, average_hierarchy_level ASC;

This SQL query constructs a recursive Common Table Expression (CTE) to create a movie hierarchy from the `aka_title` table. It joins various tables to gather keywords, cast members, and company information while filtering movies based on the production year and credit notes. Aggregate functions are used to summarize the data, including a count of related movies and string aggregation for cast members. The result is ordered by the number of related movies and average hierarchy level.
