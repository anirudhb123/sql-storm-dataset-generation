WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_info c ON mh.movie_id = c.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
popular_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    pm.title,
    pm.production_year,
    COALESCE(a.name, 'Unknown') AS actor_name,
    COALESCE(c.kind, 'Unspecified role') AS role,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    popular_movies pm
LEFT JOIN 
    cast_info ci ON pm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id 
LEFT JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_keyword mk ON pm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    pm.movie_id, pm.title, pm.production_year, a.name, c.kind
HAVING 
    COUNT(DISTINCT ci.id) > 0
ORDER BY 
    pm.production_year DESC, pm.title;
