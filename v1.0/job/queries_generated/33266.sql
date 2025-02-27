WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
, actor_roles AS (
    SELECT 
        akn.name AS actor_name,
        ct.kind AS role_name,
        ci.movie_id
    FROM 
        cast_info ci
    JOIN 
        aka_name akn ON ci.person_id = akn.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
)
, title_keywords AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.id
)
SELECT 
    mh.title,
    mh.production_year,
    COALESCE(ak.actor_name, 'No Actor') AS actor_name,
    ak.role_name,
    tk.keywords,
    mh.level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    actor_roles ak ON mh.movie_id = ak.movie_id
LEFT JOIN 
    title_keywords tk ON mh.movie_id = tk.movie_id
WHERE 
    mh.production_year IS NOT NULL
ORDER BY 
    mh.level, mh.production_year DESC;
