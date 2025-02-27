WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related')
)

SELECT 
    COALESCE(a.name, c.name) AS actor_name,
    t.title,
    t.production_year,
    COUNT(DISTINCT c.id) AS total_roles,
    AVG(NULLIF(m.level, 0)) AS average_related_movies,
    SUM(CASE 
        WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') 
        THEN CAST(mi.info AS INTEGER) 
        ELSE 0 
    END) AS total_budget,
    STRING_AGG(DISTINCT k.keyword, ', ') AS movie_keywords
FROM 
    title t
LEFT JOIN 
    cast_info ci ON t.id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    char_name c ON ci.person_id = c.imdb_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_hierarchy mh ON t.id = mh.movie_id
GROUP BY 
    actor_name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT ci.id) > 1 OR 
    AVG(NULLIF(m.level, 0)) > 1
ORDER BY 
    total_roles DESC, 
    t.production_year DESC;
