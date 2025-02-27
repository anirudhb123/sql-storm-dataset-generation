WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id, 
        mt.title, 
        mt.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.level < 5
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    k.keyword,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS actor_rank,
    COALESCE(c.kind, 'Unknown') AS company_type,
    COUNT(m.id) AS total_movies,
    AVG(t.production_year - t.production_year % 5) AS avg_decade
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    MovieHierarchy mh ON t.id = mh.movie_id
GROUP BY 
    a.name, t.title, t.production_year, k.keyword, c.kind
HAVING 
    COUNT(m.id) > 1 AND 
    AVG(t.production_year) < 2010
ORDER BY 
    avg_decade DESC, actor_rank;
