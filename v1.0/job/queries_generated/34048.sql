WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(t.title, 'Unknown Title') AS title,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.movie_id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    WHERE 
        cn.country_code = 'USA'
    
    UNION ALL
    
    SELECT 
        mk.linked_movie_id,
        COALESCE(t.title, 'Unknown Title') AS title,
        mh.level + 1
    FROM 
        movie_link mk
    JOIN 
        movie_hierarchy mh ON mk.movie_id = mh.movie_id
    JOIN 
        aka_title t ON t.movie_id = mk.linked_movie_id
)
, ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.title) AS rank
    FROM 
        movie_hierarchy mh
)
SELECT 
    r.movie_id,
    r.title,
    r.level,
    r.rank,
    COUNT(c.person_id) AS actor_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actors
FROM 
    ranked_movies r
LEFT JOIN 
    complete_cast cc ON r.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name a ON a.person_id = c.person_id
WHERE 
    r.level <= 3
GROUP BY 
    r.movie_id, r.title, r.level, r.rank
ORDER BY 
    r.level, r.rank;
