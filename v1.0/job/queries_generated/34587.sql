WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.title,
    m.production_year,
    pc.name AS production_company,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'genre') THEN 1 ELSE 0 END) AS genre_count,
    ROW_NUMBER() OVER (PARTITION BY YEAR(m.production_year) ORDER BY COUNT(DISTINCT a.id) DESC) AS actor_rank
FROM 
    movie_hierarchy m
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name pc ON mc.company_id = pc.id
LEFT JOIN 
    cast_info ci ON ci.movie_id = m.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = m.movie_id
WHERE 
    m.production_year IS NOT NULL
GROUP BY 
    m.movie_id, m.title, m.production_year, pc.name
HAVING 
    SUM(CASE WHEN pc.country_code = 'USA' THEN 1 ELSE 0 END) > 0
ORDER BY 
    m.production_year DESC, actor_rank
LIMIT 50;
