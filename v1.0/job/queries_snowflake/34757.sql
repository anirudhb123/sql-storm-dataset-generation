
WITH RECURSIVE MovieHierarchy AS (
    
    SELECT 
        m.id AS movie_id,
        m.title,
        c.person_id,
        c.role_id, 
        1 AS level
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year >= 2000

    UNION ALL

    
    SELECT 
        mh.movie_id,
        mh.title,
        c.person_id,
        c.role_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        cast_info c ON mh.movie_id = c.movie_id
    WHERE 
        NOT EXISTS (SELECT 1 FROM MovieHierarchy mh2 WHERE mh2.person_id = c.person_id AND mh2.movie_id = mh.movie_id)
)

SELECT 
    mv.title,
    COUNT(DISTINCT mh.person_id) AS total_cast,
    LISTAGG(DISTINCT n.name, ', ') WITHIN GROUP (ORDER BY n.name) AS cast_names,
    AVG(COALESCE(mk.cnt, 0)) AS avg_keywords,
    CASE 
        WHEN COUNT(DISTINCT mh.person_id) > 5 THEN 'Large Cast'
        WHEN COUNT(DISTINCT mh.person_id) BETWEEN 2 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    aka_title mv
LEFT JOIN 
    MovieHierarchy mh ON mv.id = mh.movie_id
LEFT JOIN 
    (SELECT movie_id, COUNT(keyword_id) AS cnt
     FROM movie_keyword
     GROUP BY movie_id) mk ON mv.id = mk.movie_id
LEFT JOIN 
    cast_info c ON mv.id = c.movie_id
LEFT JOIN 
    aka_name n ON c.person_id = n.person_id
WHERE 
    mv.production_year >= 2000
GROUP BY 
    mv.id, mv.title
HAVING 
    COUNT(DISTINCT mh.person_id) >= 2
ORDER BY 
    total_cast DESC, mv.title ASC;
