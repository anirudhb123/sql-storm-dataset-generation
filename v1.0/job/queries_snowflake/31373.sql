WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL 

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.depth + 1
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
ActorRoles AS (
    SELECT 
        ci.person_id,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id, rt.role
),
TopActors AS (
    SELECT 
        ar.person_id,
        ak.name,
        ROW_NUMBER() OVER (ORDER BY SUM(ar.role_count) DESC) AS rank
    FROM 
        ActorRoles ar
    JOIN 
        aka_name ak ON ar.person_id = ak.person_id
    GROUP BY 
        ar.person_id, ak.name
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    mh.kind_id,
    ta.name AS top_actor,
    ta.rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    TopActors ta ON cc.subject_id = ta.person_id
WHERE 
    mh.depth < 3
ORDER BY 
    mh.production_year DESC,
    ta.rank ASC
LIMIT 100;
