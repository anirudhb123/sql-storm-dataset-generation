
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
)

SELECT 
    p.name AS actor_name,
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY mh.production_year DESC) AS rnk,
    CASE 
        WHEN c.note IS NOT NULL THEN 'Has Note'
        ELSE 'No Note'
    END AS note_status
FROM 
    aka_name p
LEFT OUTER JOIN 
    cast_info c ON p.person_id = c.person_id
LEFT JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
GROUP BY 
    p.id, p.name, mh.movie_title, mh.production_year, c.note
HAVING 
    COUNT(DISTINCT c.movie_id) > 1
ORDER BY 
    movie_count DESC, actor_name;
