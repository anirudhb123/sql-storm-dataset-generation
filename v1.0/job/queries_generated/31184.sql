WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        NULL AS parent_movie_id,
        0 AS level
    FROM 
        aka_title m 
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL 

    SELECT 
        mk.linked_movie_id,
        linked.title AS movie_title,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM 
        movie_link mk
    JOIN 
        MovieHierarchy mh ON mk.movie_id = mh.movie_id
    JOIN 
        aka_title linked ON mk.linked_movie_id = linked.id
)

SELECT 
    p.name,
    p.gender,
    m.movie_title,
    mh.parent_movie_id,
    COUNT(c.id) AS cast_count,
    AVG(CASE WHEN m.production_year IS NOT NULL THEN m.production_year ELSE NULL END) AS avg_production_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER(PARTITION BY p.id ORDER BY m.production_year DESC) AS rank
FROM 
    person_info pi
JOIN 
    aka_name p ON pi.person_id = p.person_id
LEFT JOIN 
    complete_cast cc ON p.id = cc.subject_id
LEFT JOIN 
    MovieHierarchy mh ON cc.movie_id = mh.movie_id
LEFT JOIN 
    aka_title m ON mh.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    cast_info c ON p.id = c.person_id AND c.movie_id = m.id
WHERE 
    p.gender IS NOT NULL
    AND m.production_year BETWEEN 2000 AND 2020
GROUP BY 
    p.id, m.movie_title, mh.parent_movie_id
HAVING 
    COUNT(c.id) > 5
ORDER BY 
    p.name, mh.level DESC, avg_production_year DESC;

