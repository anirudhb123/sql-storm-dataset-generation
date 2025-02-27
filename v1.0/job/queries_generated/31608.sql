WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        m.id AS root_movie_id
    FROM 
        title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        h.level + 1 AS level,
        h.root_movie_id
    FROM 
        title e
    JOIN 
        movie_hierarchy h ON e.episode_of_id = h.movie_id
)

SELECT 
    ak.name AS actor_name,
    mk.keyword AS movie_keyword,
    m.title AS movie_title,
    COUNT(*) OVER (PARTITION BY ak.id ORDER BY m.production_year DESC) AS num_movies,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
    CASE 
        WHEN mi.info IS NOT NULL THEN mi.info 
        ELSE 'No Information Available' 
    END AS movie_info,
    m.production_year
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    title m ON mh.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Detailed Info')
WHERE 
    ak.name IS NOT NULL 
    AND mk.keyword IS NOT NULL
    AND m.production_year > 2000
GROUP BY 
    ak.id, mk.keyword, m.title, mi.info
ORDER BY 
    m.production_year DESC, ak.name;
