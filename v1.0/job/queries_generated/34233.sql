WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA'
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        t.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.movie_id
    JOIN 
        title m ON m.id = t.movie_id
)
SELECT 
    h.title,
    h.production_year,
    COUNT(DISTINCT c.person_id) AS actor_count,
    AVG(CASE WHEN p.gender = 'F' THEN 1 ELSE NULL END) AS female_percentage,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles
FROM 
    movie_hierarchy h
LEFT JOIN 
    complete_cast cc ON h.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    name p ON c.person_id = p.imdb_id
LEFT JOIN 
    movie_keyword mk ON h.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    role_type ci ON c.role_id = ci.id
WHERE 
    h.production_year IS NOT NULL
GROUP BY 
    h.title, h.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 5
ORDER BY 
    h.production_year DESC, actor_count DESC;
