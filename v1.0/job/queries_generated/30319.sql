WITH RECURSIVE MovieHierarchy AS (
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
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title at ON at.id = ml.linked_movie_id
    WHERE 
        at.production_year >= 2000
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        cn.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        aka_name cn ON ci.person_id = cn.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(ar.actor_name) AS actor_count,
        COALESCE(MAX(ar.role_order), 0) AS max_role_order
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorRoles ar ON mh.movie_id = ar.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_count,
    CASE 
        WHEN fm.max_role_order < 5 THEN 'Fewer roles'
        WHEN fm.max_role_order BETWEEN 5 AND 10 THEN 'Moderate roles'
        ELSE 'Many roles'
    END AS role_category,
    CASE 
        WHEN fm.actor_count IS NULL THEN 'No actors'
        WHEN fm.actor_count > 50 THEN 'Blockbuster'
        ELSE 'Indie'
    END AS movie_category
FROM 
    FilteredMovies fm
WHERE 
    fm.actor_count IS NOT NULL
ORDER BY 
    fm.production_year DESC,
    fm.actor_count DESC;
