WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL  -- Top-level movies with no episodes
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        e.kind_id,
        mh.level + 1
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
), 

actor_stats AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(m.production_year) AS avg_year,
        STRING_AGG(DISTINCT m.title, ', ') AS movie_titles
    FROM 
        cast_info c
    JOIN 
        aka_title m ON c.movie_id = m.id
    WHERE 
        c.nr_order IS NOT NULL  -- Only consider actors with a defined order
    GROUP BY 
        c.person_id
),

company_counts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT m.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name m ON mc.company_id = m.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    a.id AS actor_id,
    n.name AS actor_name,
    s.movie_count,
    s.avg_year,
    s.movie_titles,
    COALESCE(cc.company_count, 0) AS company_count,
    mh.level AS movie_level
FROM 
    actor_stats s
JOIN 
    aka_name n ON s.person_id = n.person_id
LEFT JOIN 
    company_counts cc ON cc.movie_id IN (
        SELECT DISTINCT mc.movie_id 
        FROM movie_companies mc
        JOIN cast_info ci ON mc.movie_id = ci.movie_id 
        WHERE ci.person_id = s.person_id
     )
JOIN 
    movie_hierarchy mh ON mh.movie_id IN (
        SELECT DISTINCT m.id FROM aka_title m 
        JOIN cast_info ci ON m.id = ci.movie_id 
        WHERE ci.person_id = s.person_id
    )
WHERE 
    s.movie_count > 5  -- Actors involved in more than 5 movies
ORDER BY 
    s.movie_count DESC, 
    n.name;
