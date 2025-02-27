WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(t.title, 'Unknown Title') AS title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        title t ON m.movie_id = t.imdb_id
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        mc.linked_movie_id,
        COALESCE(mt.title, 'Unknown Title') AS title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link mc
    JOIN 
        movie_hierarchy mh ON mc.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON mc.linked_movie_id = mt.movie_id
)

SELECT 
    p.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    AVG(m.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY p.name ORDER BY COUNT(DISTINCT mc.movie_id) DESC) AS actor_rank
FROM 
    cast_info ci
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mc.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_hierarchy m ON ci.movie_id = m.movie_id
GROUP BY 
    p.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5
ORDER BY 
    avg_production_year DESC,
    total_movies DESC
LIMIT 10;
