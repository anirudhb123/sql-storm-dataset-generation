WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA'
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title n ON ml.linked_movie_id = n.id
)

SELECT 
    p.person_id,
    p.name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    AVG(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MAX(mh.production_year) AS latest_movie_year
FROM 
    aka_name p
LEFT JOIN 
    cast_info c ON p.person_id = c.person_id
LEFT JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
WHERE 
    p.name IS NOT NULL 
    AND p.name NOT LIKE '%test%'
GROUP BY 
    p.person_id, p.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 3
ORDER BY 
    total_movies DESC, latest_movie_year DESC
LIMIT 10;

