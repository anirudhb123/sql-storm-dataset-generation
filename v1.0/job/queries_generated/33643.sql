WITH RECURSIVE MovieHierarchy AS (
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
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        movie_link m
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

ActorRoles AS (
    SELECT 
        ci.movie_id,
        rn.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        aka_name rn ON ci.person_id = rn.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),

MovieInfo AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info LIKE '%budget%' THEN mi.info END) AS budget,
        MAX(CASE WHEN it.info LIKE '%box office%' THEN mi.info END) AS box_office
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    COALESCE(mh.level, 0) AS hierarchy_level,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(ar.actor_name, 'Unknown Actor') AS primary_actor,
    COALESCE(ar.role_name, 'Unknown Role') AS primary_role,
    COALESCE(mi.budget, 'N/A') AS budget,
    COALESCE(mi.box_office, 'N/A') AS box_office
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    ActorRoles ar ON mh.movie_id = ar.movie_id AND ar.role_order = 1
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE 
    (mh.production_year >= 2000 OR mh.production_year IS NULL)
ORDER BY 
    mh.production_year DESC, mh.title;
