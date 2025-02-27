WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        1 AS level,
        CAST(m.title AS text) AS full_title
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.linked_movie_id AS movie_id,
        m2.title, 
        m2.production_year, 
        mh.level + 1,
        CAST(mh.full_title || ' -> ' || m2.title AS text) AS full_title
    FROM 
        movie_link m
    JOIN 
        aka_title m2 ON m.linked_movie_id = m2.id
    JOIN 
        movie_hierarchy mh ON m.movie_id = mh.movie_id
    WHERE 
        mh.level < 3 -- Limit to a depth of 3
)
SELECT 
    t.title,
    a.name AS actor_name,
    t.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(r.role_duration) AS average_role_duration,
    ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS rank
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id 
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id 
LEFT JOIN (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.id) AS role_duration -- Assume a function that calculates role duration
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
) r ON mh.movie_id = r.movie_id 
GROUP BY 
    t.title, a.name, t.production_year 
ORDER BY 
    t.production_year DESC, keyword_count DESC
LIMIT 50;
