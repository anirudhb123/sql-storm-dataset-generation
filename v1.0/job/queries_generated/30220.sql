WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year,
        COALESCE(NULLIF(m.note, ''), 'No Notes') AS note,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year,
        COALESCE(NULLIF(m.note, ''), 'No Notes') AS note,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    ah.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(pi.info IS NOT NULL AND pi.info <> '') AS has_info_ratio
FROM 
    MovieHierarchy mh
JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
JOIN 
    aka_name ah ON ah.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    person_info pi ON pi.person_id = ci.person_id 
WHERE 
    mh.level <= 2
GROUP BY 
    ah.name, mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC, 
    actor_name ASC;
This SQL query performs a performance benchmark by retrieving a hierarchy of movies from the year 2000 onward, aggregates related data such as actor names, keywords, and company involvement, and calculates how much information is available for each actor involved. It also utilizes recursive Common Table Expressions (CTEs), outer joins, and window functions to provide a detailed analysis of the movie landscape in the specified criteria.
