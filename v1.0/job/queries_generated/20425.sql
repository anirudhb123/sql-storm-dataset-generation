WITH recursive movie_hierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        NULL::integer AS parent_id,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    mh.parent_id,
    mh.level,
    COUNT(DISTINCT mc.company_id) AS comp_count,
    STRING_AGG(DISTINCT c.name, ', ') AS company_names,
    SUM(
        CASE 
            WHEN mi.info IS NULL THEN 0 
            ELSE LENGTH(mi.info) 
        END
    ) AS total_info_length,
    SUM(CASE WHEN mk.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY mh.level DESC) AS actor_movie_rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON ci.person_id = a.person_id
JOIN 
    movie_hierarchy mh ON mh.movie_id = ci.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    company_name c ON c.id = mc.company_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
JOIN 
    aka_title t ON mh.movie_id = t.id
WHERE 
    (mh.level <= 2 AND t.production_year >= 2000)
    AND (a.name IS NOT NULL OR a.name != '')
    AND (c.country_code IS NOT NULL AND c.country_code IS NOT NULL)
GROUP BY 
    a.name, t.title, mh.parent_id, mh.level
HAVING 
    COUNT(DISTINCT ci.movie_id) > 5
ORDER BY 
    actor_movie_rank, total_info_length DESC;
