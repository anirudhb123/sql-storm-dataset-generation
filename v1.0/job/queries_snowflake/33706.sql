
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM 
        aka_title et
    JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id
),
RoleCounts AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
Companies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(rc.role, 'Unknown') AS role,
    COALESCE(rc.role_count, 0) AS total_roles,
    COALESCE(c.company_names, 'No Companies') AS companies,
    COALESCE(c.company_types, 'No Types') AS types,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY COALESCE(rc.role_count, 0) DESC) AS role_rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    RoleCounts rc ON mh.movie_id = rc.movie_id
LEFT JOIN 
    Companies c ON mh.movie_id = c.movie_id
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
    AND (mh.title LIKE 'A%' OR mh.title LIKE 'B%')
ORDER BY 
    mh.production_year DESC, 
    role_rank ASC;
