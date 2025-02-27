WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

actors_with_roles AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        ct.kind AS role,
        ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY at.production_year DESC) AS recent_role
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        at.production_year >= 2010 AND
        ak.name IS NOT NULL
),

movie_details AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT ac.actor_name) AS actor_count,
        AVG(m.production_year - r.production_year) AS average_year_diff
    FROM 
        movie_hierarchy m
    LEFT JOIN 
        actors_with_roles ac ON m.title = ac.movie_title
    LEFT JOIN 
        aka_title r ON m.movie_id = r.id
    GROUP BY 
        m.movie_id
)

SELECT 
    md.movie_id,
    md.actor_count,
    md.average_year_diff,
    mh.title AS movie_title,
    mh.production_year AS release_year
FROM 
    movie_details md
JOIN 
    movie_hierarchy mh ON md.movie_id = mh.movie_id
WHERE 
    md.actor_count > 0
ORDER BY 
    md.average_year_diff DESC, 
    md.actor_count DESC
LIMIT 50;
