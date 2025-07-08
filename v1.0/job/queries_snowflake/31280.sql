
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.level < 3
),
company_info AS (
    SELECT 
        c.id AS company_id,
        c.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        LISTAGG(DISTINCT mt.title, ', ') WITHIN GROUP (ORDER BY mt.title) AS movie_titles
    FROM 
        company_name c
    LEFT JOIN 
        movie_companies mc ON mc.company_id = c.id
    LEFT JOIN 
        aka_title mt ON mt.id = mc.movie_id
    GROUP BY 
        c.id, c.name
),
cast_roles AS (
    SELECT 
        ak.name AS actor_name,
        mt.title,
        rc.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year DESC) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    JOIN 
        aka_title mt ON mt.id = ci.movie_id
    JOIN 
        role_type rc ON rc.id = ci.role_id
    WHERE 
        ci.note IS NULL
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    ci.company_name,
    ci.movie_count,
    ci.movie_titles,
    LISTAGG(DISTINCT cr.actor_name || ' as ' || cr.role_name, ', ') WITHIN GROUP (ORDER BY cr.actor_name) AS actors
FROM 
    movie_hierarchy mh
JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
JOIN 
    company_info ci ON ci.company_id = mc.company_id
LEFT JOIN 
    cast_roles cr ON cr.title = mh.title
WHERE 
    mh.production_year > 2000
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, ci.company_name, ci.movie_count, ci.movie_titles
ORDER BY 
    mh.production_year DESC, ci.movie_count DESC
LIMIT 100;
