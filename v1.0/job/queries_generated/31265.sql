WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title AS m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        l.linked_movie_id,
        m.title,
        m.production_year,
        depth + 1
    FROM 
        movie_link AS l
    JOIN 
        aka_title AS m ON l.linked_movie_id = m.id
    JOIN 
        movie_hierarchy AS mh ON l.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3  -- Limit depth of recursion
),

actor_role_counts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        ARRAY_AGG(DISTINCT rt.role) AS roles
    FROM 
        cast_info AS ci
    JOIN 
        role_type AS rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id
),

top_actors AS (
    SELECT 
        ak.name,
        acr.movie_count,
        acr.roles
    FROM 
        aka_name AS ak
    JOIN 
        actor_role_counts AS acr ON ak.person_id = acr.person_id
    WHERE 
        acr.movie_count > 5
)

SELECT 
    m.title,
    m.production_year,
    ta.name AS top_actor,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    AVG((SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = m.id)) AS avg_info_per_movie,
    '%s' AS title_info  -- String expression placeholder for additional info
FROM 
    movie_hierarchy AS m
LEFT JOIN 
    movie_keyword AS mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    complete_cast AS cc ON m.movie_id = cc.movie_id
JOIN 
    top_actors AS ta ON cc.subject_id = ta.person_id
GROUP BY 
    m.movie_id, m.title, m.production_year, ta.name
HAVING 
    COUNT(DISTINCT mk.keyword) > 2 AND AVG((SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = m.id)) >= 1
ORDER BY 
    m.production_year DESC,
    keyword_count DESC;
