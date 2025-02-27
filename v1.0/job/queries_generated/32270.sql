WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 3
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = t.id) AS total_cast_members,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT cr.id) OVER(PARTITION BY t.id) AS character_roles,
    CASE
        WHEN (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = t.id 
              AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Distributor')) > 0 
        THEN 'Distributed'
        ELSE 'Not Distributed'
    END AS distribution_status
FROM 
    MovieHierarchy mh
JOIN 
    title t ON mh.movie_id = t.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year IS NOT NULL
GROUP BY 
    a.name, t.id, t.title, t.production_year
ORDER BY 
    t.production_year DESC, character_roles DESC;
