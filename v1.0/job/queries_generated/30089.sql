WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS depth
    FROM 
        aka_title m 
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')  
      AND 
        m.production_year BETWEEN 2000 AND 2023

    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id, 
        m.title AS movie_title,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
      a.name AS actor_name,
      m.movie_title,
      m.depth,
      COUNT(DISTINCT c.id) AS cast_member_count,
      STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
      SUM(CASE WHEN p.gender = 'M' THEN 1 ELSE 0 END) AS male_actors_count,
      SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_actors_count
FROM 
    movie_hierarchy m
JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'gender')
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.depth <= 2
GROUP BY 
    a.name, m.movie_title, m.depth
ORDER BY 
    m.depth, male_actors_count DESC, female_actors_count DESC;
