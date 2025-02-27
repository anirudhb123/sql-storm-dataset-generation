WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.title, 
        mt.production_year, 
        0 AS level,
        mt.id AS movie_id,
        NULL AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1 -- Assume 1 is for movies

    UNION ALL

    SELECT 
        mt.title, 
        mt.production_year,
        mh.level + 1,
        mt.id AS movie_id,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        coalesce(ci.person_id, -1) AS actor_id,
        ci.note AS role_note,
        mt.info AS additional_info
    FROM 
        MovieHierarchy m
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = m.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.movie_id AND ci.person_role_id IS NOT NULL
    LEFT JOIN 
        movie_info mt ON mt.movie_id = m.movie_id
),
ActorRoles AS (
    SELECT 
        ai.movie_id,
        ai.actor_id,
        ai.title,
        ai.additional_info,
        ROW_NUMBER() OVER (PARTITION BY ai.movie_id ORDER BY role_note) AS rn,
        COUNT(*) OVER (PARTITION BY ai.movie_id) AS total_roles
    FROM 
        MovieInfo ai
    WHERE 
        ai.actor_id IS NOT NULL
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    CASE 
        WHEN a.actor_id = -1 THEN 'No Actor Assigned'
        ELSE n.name
    END AS actor_name,
    ar.role_note,
    ar.total_roles,
    ar.rn
FROM 
    MovieHierarchy m
LEFT JOIN 
    ActorRoles ar ON ar.movie_id = m.movie_id
LEFT JOIN 
    aka_name n ON n.person_id = ar.actor_id
ORDER BY 
    m.production_year DESC, 
    ar.total_roles DESC, 
    actor_name
LIMIT 100;

This SQL query is quite complex. It begins with a recursive CTE (`MovieHierarchy`) to explore movie links, generating a hierarchy of movies. The `MovieInfo` CTE gathers necessary details about movies and actors, including roles and additional information. The `ActorRoles` CTE assigns row numbers to roles within each movie, allowing for easy ranking. Finally, the main query selects from this hierarchical structure, handling missing actor assignments gracefully and ordering results for presentation. The final result limits the output to the top 100 entries.
