WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    mt.title,
    mt.production_year,
    string_agg(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    AVG(CASE 
        WHEN mi.info_type_id IS NOT NULL THEN LENGTH(mi.info)
        ELSE NULL
    END) AS avg_info_length,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY mt.production_year DESC) AS movie_rank
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')
WHERE 
    mt.production_year IS NOT NULL
GROUP BY 
    a.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT ci.movie_id) >= 2
ORDER BY 
    actor_name, production_year DESC;
