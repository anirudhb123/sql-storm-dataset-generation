WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id, 
        m.title, 
        mh.level + 1
    FROM 
        alias_title m
    JOIN 
        movie_link ml ON m.id = ml.movie_id
    JOIN 
        MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
),
ActorRoles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS total_roles,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY COUNT(DISTINCT ci.role_id) DESC) AS role_rank
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id, 
        ci.movie_id
),
TopActors AS (
    SELECT 
        a.person_id,
        ak.name AS actor_name,
        ar.total_roles
    FROM 
        ActorRoles ar
    JOIN 
        aka_name ak ON ar.person_id = ak.person_id
    WHERE 
        ar.role_rank <= 10 
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(DISTINCT ci.note, ', ') AS notes,
        COUNT(DISTINCT mi.info) AS info_count,
        MAX(CASE WHEN mt.info_type_id = 1 THEN mi.info END) AS main_info
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        info_type mt ON mi.info_type_id = mt.id
    GROUP BY 
        m.id, 
        m.title
)
SELECT 
    mh.title AS Movie_Title,
    ta.actor_name AS Actor_Name,
    mi.notes AS Movie_Notes,
    mi.info_count AS Movie_Info_Count,
    mh.level AS Movie_Level
FROM 
    MovieHierarchy mh
JOIN 
    TopActors ta ON mh.movie_id = ta.movie_id
JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.level <= 3
ORDER BY 
    mi.info_count DESC, 
    mh.title;

