WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth,
        CAST(m.title AS TEXT) AS movie_path
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1,
        CAST(mh.movie_path || ' > ' || m.title AS TEXT) AS movie_path
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title parent ON parent.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = parent.id
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movies_count,
    AVG(w.profit) AS average_profit,
    STRING_AGG(DISTINCT t.title, ', ') AS titles,
    MAX(t.production_year) AS last_movie_year,
    CASE 
        WHEN COUNT(DISTINCT c.movie_id) > 5 THEN 'Highly Active'
        WHEN COUNT(DISTINCT c.movie_id) BETWEEN 3 AND 5 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS activity_level
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    (SELECT 
         movie_id, 
         SUM(info::NUMERIC) AS profit 
     FROM 
         movie_info 
     WHERE 
         info_type_id = (SELECT id FROM info_type WHERE info = 'profit')
     GROUP BY 
         movie_id) w ON w.movie_id = t.id
JOIN 
    MovieHierarchy mh ON mh.movie_id = t.id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name
HAVING 
    AVG(w.profit) IS NOT NULL 
    AND MAX(t.production_year) >= 2000
ORDER BY 
    movies_count DESC, 
    last_movie_year DESC 
LIMIT 10;

