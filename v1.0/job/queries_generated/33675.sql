WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_link ml ON t.id = ml.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'follow-up')
    
    UNION ALL
    
    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.linked_movie_id
    JOIN 
        aka_title t ON ml.movie_id = t.id
)

SELECT 
    a.name AS actor_name,
    COALESCE(a.gender, 'Unknown') AS actor_gender,
    m.title AS movie_title,
    mh.level AS movie_level,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    ARRAY_AGG(DISTINCT CONCAT(ct.kind, ': ', mc.note)) AS company_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    MovieHierarchy mh ON cc.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    mh.production_year >= 2000 
    AND mh.production_year < 2023
GROUP BY 
    a.name, a.gender, m.title, mh.level
ORDER BY 
    keyword_count DESC, actor_name ASC;
