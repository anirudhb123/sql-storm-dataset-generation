WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        t.title, 
        1 AS level 
    FROM 
        aka_title t 
    JOIN 
        title m ON t.movie_id = m.id 
    WHERE 
        m.production_year = 2023
    
    UNION ALL
    
    SELECT 
        mc.linked_movie_id, 
        t.title, 
        mh.level + 1 
    FROM 
        movie_link mc 
    JOIN 
        movie_hierarchy mh ON mc.movie_id = mh.movie_id 
    JOIN 
        title t ON mc.linked_movie_id = t.id 
)
SELECT 
    ak.name AS actor_name, 
    t.title AS movie_title, 
    mh.level AS movie_level, 
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE 
            WHEN mi.info IS NOT NULL THEN 1 
            ELSE 0 
        END) AS info_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.person_id) FILTER (WHERE ci.nr_order = 1) AS main_cast_count,
    RANK() OVER (PARTITION BY mh.movie_id ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank
FROM 
    movie_hierarchy mh 
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id 
JOIN 
    aka_name ak ON ci.person_id = ak.person_id 
JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id 
JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id 
JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    title t ON mh.movie_id = t.id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id 
LEFT JOIN 
    role_type r ON ci.role_id = r.id 
WHERE 
    (ak.name IS NOT NULL AND ak.name <> '') 
    AND (mi.info_type_id IS NOT NULL AND mi.info_type_id IN (1, 2))
    AND (mh.level <= 3)
GROUP BY 
    ak.name, t.title, mh.level 
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    movie_level, actor_rank;
