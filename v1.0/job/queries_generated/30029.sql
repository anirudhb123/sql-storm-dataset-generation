WITH RECURSIVE movie_hierarchy AS (
    -- Base case: select top-level movies
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    -- Recursive case: select episodes of stored movies
    SELECT 
        at.id AS movie_id,
        at.title,
        mh.depth + 1 AS depth
    FROM 
        aka_title at
    INNER JOIN 
        movie_hierarchy mh ON at.episode_of_id = mh.movie_id
),
movie_info_ex AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.depth,
        mi.info AS movie_desc,
        COALESCE(mi.note, 'No notes available') AS note,
        (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mh.movie_id) AS keyword_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
),
actor_movies AS (
    SELECT 
        a.name AS actor_name,
        mt.title AS movie_title,
        COUNT(CASE WHEN c.nr_order IS NOT NULL THEN 1 END) AS total_roles
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    INNER JOIN 
        aka_title mt ON c.movie_id = mt.movie_id
    GROUP BY 
        a.name, mt.title
),
top_actors AS (
    SELECT 
        actor_name,
        SUM(total_roles) AS total_roles
    FROM 
        actor_movies
    GROUP BY 
        actor_name
    HAVING 
        SUM(total_roles) > 2
    ORDER BY 
        total_roles DESC
    LIMIT 10
)

SELECT 
    m.movie_id,
    m.title,
    m.depth,
    m.movie_desc,
    m.note,
    m.keyword_count,
    ta.actor_name,
    ta.total_roles
FROM 
    movie_info_ex m
LEFT JOIN 
    top_actors ta ON m.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id IN (SELECT person_id FROM aka_name WHERE name = ta.actor_name))
WHERE 
    m.depth <= 1
ORDER BY 
    m.keyword_count DESC, m.title ASC;

