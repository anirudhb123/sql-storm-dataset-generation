WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL

    SELECT 
        et.id AS movie_id, 
        et.title, 
        et.production_year, 
        mh.level + 1 AS level
    FROM 
        aka_title et
    JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id
),
ActorRoles AS (
    SELECT 
        ci.movie_id, 
        ak.name AS actor_name, 
        rt.role AS role_name, 
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieKeys AS (
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
MovieInfoWithRoles AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ar.actor_name, 'Unknown') AS leading_actor,
        COALESCE(ar.role_name, 'N/A') AS leading_role,
        mk.keywords
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorRoles ar ON mh.movie_id = ar.movie_id AND ar.actor_order = 1
    LEFT JOIN 
        MovieKeys mk ON mh.movie_id = mk.movie_id
)
SELECT 
    mi.movie_id,
    mi.title,
    mi.production_year,
    mi.leading_actor,
    mi.leading_role,
    mi.keywords,
    COUNT(mc.company_id) AS company_count,
    COUNT(DISTINCT ci.subject_id) AS unique_cast_count
FROM 
    MovieInfoWithRoles mi
LEFT JOIN 
    movie_companies mc ON mi.movie_id = mc.movie_id
LEFT JOIN 
    complete_cast ci ON mi.movie_id = ci.movie_id
WHERE 
    mi.production_year >= 2000 
    AND (mi.keywords IS NULL OR mi.keywords LIKE '%Action%')
GROUP BY 
    mi.movie_id, mi.title, mi.production_year, mi.leading_actor, mi.leading_role, mi.keywords
ORDER BY 
    COUNT(DISTINCT ci.subject_id) DESC, 
    mi.production_year ASC
LIMIT 50;
