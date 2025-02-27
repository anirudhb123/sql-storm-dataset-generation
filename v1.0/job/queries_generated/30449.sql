WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level 
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000  -- Filter for recent movies
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        h.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy h ON ml.movie_id = h.movie_id
    WHERE 
        h.level < 5  -- Limit depth of recursion to avoid excessive joins
),
ActorRoles AS (
    SELECT 
        c.person_id,
        c.movie_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
),
RelevantActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        ar.movie_id,
        ar.role,
        COALESCE(pi.info, 'No info available') AS additional_info
    FROM 
        aka_name a
    LEFT JOIN 
        ActorRoles ar ON a.person_id = ar.person_id
    LEFT JOIN 
        person_info pi ON a.person_id = pi.person_id AND pi.info_type_id = 1  -- Info type for biography
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ra.actor_id,
    ra.name AS actor_name,
    ra.role,
    ra.additional_info
FROM 
    MovieHierarchy mh
LEFT JOIN 
    RelevantActorInfo ra ON mh.movie_id = ra.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
WHERE 
    mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE 'Action%')  -- Filter for Action movies
ORDER BY 
    mh.production_year DESC,
    ra.role_order
LIMIT 100;  -- Limit output for performance benchmarking
