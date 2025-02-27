WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        0 AS depth
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    WHERE 
        t.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        CONCAT('Sequel of: ', mh.movie_title) AS movie_title,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON ml.linked_movie_id = mh.movie_id
)

SELECT 
    p.id AS person_id,
    n.name AS actor_name,
    COUNT(DISTINCT ci.movie_id) AS movies_count,
    AVG(m.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT t.title, ', ') AS titles_featured,
    MAX(CASE WHEN m.production_year < 2010 THEN 'Pre-2010' ELSE 'Post-2010' END) AS year_category,
    MAX(COALESCE(ci.note, 'No Note')) AS notes
FROM 
    aka_name n
JOIN 
    cast_info ci ON n.person_id = ci.person_id
JOIN 
    movie_hierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN 
    title t ON m.movie_id = t.id
LEFT JOIN 
    person_info pi ON n.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Bio')
GROUP BY 
    p.id, n.name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 2
ORDER BY 
    movies_count DESC, avg_production_year ASC;
