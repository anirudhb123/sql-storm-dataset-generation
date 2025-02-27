WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        CONCAT(mh.path, ' -> ', at.title)
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    m.title AS movie_title,
    m.production_year AS year,
    STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.person_id) OVER (PARTITION BY m.id) AS cast_count,
    MAX(pi.info) AS latest_award
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info c ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = m.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Award' LIMIT 1)
LEFT JOIN 
    person_info pi ON pi.person_id = c.person_id
WHERE 
    m.level <= 2
GROUP BY 
    m.movie_id
HAVING 
    COUNT(DISTINCT c.person_id) > 2 
ORDER BY 
    m.production_year DESC, 
    cast_count DESC;

This SQL query accomplishes the following:
- Uses a recursive Common Table Expression (CTE) called `MovieHierarchy` to build a hierarchy of movies linked by direct connections, limited to those produced from the year 2000 onward.
- The main SELECT retrieves information about these movies, including titles, production years, cast names, associated keywords, and the count of unique cast members.
- It also includes null logic by using left joins and a condition in the WHERE clause to limit to a maximum depth of the movie hierarchy.
- It filters out movies that don't have more than two unique cast members.
- It aggregates cast names and keywords into a format suitable for output, while using window functions to calculate the cast count.
- Finally, the results are ordered by production year (most recent first) and the count of unique cast members, providing a performant means of assessing the hierarchy of popular movies.
