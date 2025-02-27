WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m 
    WHERE 
        m.production_year > 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml 
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        a.production_year > 2000
),
ranked_cast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
movies_with_keywords AS (
    SELECT 
        mt.movie_id,
        string_agg(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    mh.movie_title,
    mh.production_year,
    mc.company_name,
    r.actor_name,
    r.role,
    mw.keywords,
    COUNT(e.movie_id) AS number_of_equivalent_movies
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    ranked_cast r ON mh.movie_id = r.movie_id
LEFT JOIN 
    movies_with_keywords mw ON mh.movie_id = mw.movie_id
LEFT JOIN 
    movie_link e ON mh.movie_id = e.movie_id
GROUP BY 
    mh.movie_id, mc.company_name, r.actor_name, r.role, mw.keywords
HAVING 
    COUNT(e.movie_id) > 0 OR mw.keywords IS NOT NULL
ORDER BY 
    mh.production_year DESC, mh.movie_title;
