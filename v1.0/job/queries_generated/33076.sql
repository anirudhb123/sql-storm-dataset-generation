WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        m.movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        title t ON t.id = a.id
    WHERE 
        t.production_year >= 2000
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        array_agg(DISTINCT k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
top_actors AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        COUNT(ci.person_id) AS roles_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.nr_order < 3 -- Top 2 actors
    GROUP BY 
        ci.movie_id, a.name
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(t.keywords, '{}') AS keywords,
    COALESCE(t.actor_name, 'Unknown Actor') AS actor_name,
    mh.level,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    SUM(CASE WHEN a.gender = 'F' THEN 1 ELSE 0 END) AS female_cast_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    top_actors t ON mh.movie_id = t.movie_id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, t.keywords, t.actor_name, mh.level
HAVING 
    COUNT(DISTINCT ci.person_id) > 5 -- Only movies with more than 5 cast members
ORDER BY 
    mh.production_year DESC,  
    total_cast DESC;
