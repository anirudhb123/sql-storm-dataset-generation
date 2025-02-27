WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        ak.title, 
        ak.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN aka_title ak ON ml.movie_id = ak.id
    JOIN movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
),
actor_roles AS (
    SELECT 
        DISTINCT ai.person_id, 
        a.name, 
        r.role, 
        count(c.movie_id) AS total_movies
    FROM 
        cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    WHERE 
        r.role NOT LIKE '%extras%' -- Exclude extras
    GROUP BY 
        ai.person_id, a.name, r.role
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ai.total_movies, 0) AS total_roles,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS role_rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN actor_roles ai ON mh.movie_id = ai.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.total_roles,
    STRING_AGG(DISTINCT ar.name || ' (' || ar.role || ')', ', ') AS actors
FROM 
    movie_details md
LEFT JOIN cast_info ci ON md.movie_id = ci.movie_id
LEFT JOIN aka_name ar ON ci.person_id = ar.person_id
WHERE 
    md.total_roles >= 2 -- Only show movies with at least 2 main roles
GROUP BY 
    md.movie_id, md.title, md.production_year, md.total_roles
HAVING 
    md.production_year = (SELECT MAX(production_year) FROM movie_details) -- Only latest year
ORDER BY 
    md.total_roles DESC, 
    md.title;
