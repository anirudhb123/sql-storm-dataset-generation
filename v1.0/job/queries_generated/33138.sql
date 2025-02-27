WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        NULL::integer AS parent_movie_id,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    p.name AS person_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT ci.id) AS cast_count,
    AVG(mi.info_length) AS avg_info_length,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.id) DESC) AS year_rank
FROM 
    cast_info ci
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    MovieHierarchy mh ON t.id = mh.movie_id
WHERE 
    mh.level < 2 
    AND t.production_year BETWEEN 2000 AND 2020
    AND (mi.info IS NOT NULL OR mi.note IS NOT NULL)
GROUP BY 
    p.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT ci.id) >= 2
ORDER BY 
    avg_info_length DESC;

This query accomplishes the following:
- It creates a recursive CTE to build a hierarchy of movies based on links to ensure relationships between movies are captured.
- It joins multiple tables to bring in information about the cast, movie details, and associated keywords.
- It calculates aggregate values such as count of distinct cast members and average length of movie info, while filtering based on various conditions.
- It incorporates string aggregation to compile keywords associated with each movie.
- It utilizes a composite ranking mechanism to rank movies based on their cast size within their production years.
- It employs LEFT JOINs to allow for NULL handling in the information retrieval process while ensuring the results remain comprehensive.
