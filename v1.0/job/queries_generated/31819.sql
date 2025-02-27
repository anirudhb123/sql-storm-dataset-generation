WITH RECURSIVE HierarchicalMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        hm.level + 1,
        hm.movie_id AS parent_id
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        HierarchicalMovies hm ON ml.movie_id = hm.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mi.info, 'N/A') AS info,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS year_rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        m.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.id AS actor_id,
        a.person_id,
        c.movie_id,
        r.role,
        rn.rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN (
        SELECT 
            person_id,
            ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY nr_order) AS rank
        FROM 
            cast_info
        GROUP BY 
            person_id, nr_order
    ) rn ON c.person_id = rn.person_id
)
SELECT 
    DISTINCT 
    hm.movie_id,
    hm.movie_title,
    mi.info AS movie_info,
    ar.actor_id,
    ar.role AS actor_role,
    mi.production_year,
    CASE 
        WHEN mi.year_rank < 3 THEN 'Top 2 Movies of Year'
        ELSE 'Other Movies'
    END AS category,
    CASE 
        WHEN ar.role IS NULL THEN 'No Role Assigned'
        ELSE ar.role
    END AS adjusted_role
FROM 
    HierarchicalMovies hm
LEFT JOIN 
    MovieInfo mi ON hm.movie_id = mi.movie_id
LEFT JOIN 
    ActorRoles ar ON hm.movie_id = ar.movie_id
WHERE 
    ar.actor_id IS NOT NULL OR hm.parent_id IS NULL
ORDER BY 
    hm.level, mi.production_year DESC, hm.movie_title;
