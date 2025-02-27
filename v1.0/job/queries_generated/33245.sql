WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.imdb_index,
        1 AS level
    FROM 
        aka_title AS t
    WHERE 
        t.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.movie_id AS movie_id,
        t.title,
        t.production_year,
        t.imdb_index,
        mh.level + 1 
    FROM 
        movie_link AS m
    JOIN 
        aka_title AS t ON m.linked_movie_id = t.id
    JOIN 
        movie_hierarchy AS mh ON m.movie_id = mh.movie_id
)
SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    h.imdb_index,
    COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS aliases,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    COUNT(DISTINCT mc.company_id) AS company_count,
    RANK() OVER (PARTITION BY h.production_year ORDER BY h.title) AS title_rank
FROM 
    movie_hierarchy h
LEFT JOIN 
    cast_info ci ON ci.movie_id = h.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = h.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = h.movie_id
WHERE 
    h.production_year BETWEEN 2000 AND 2023
GROUP BY 
    h.movie_id, h.title, h.production_year, h.imdb_index
HAVING 
    COUNT(DISTINCT ci.person_id) > 2
ORDER BY 
    h.production_year DESC, title_rank;
