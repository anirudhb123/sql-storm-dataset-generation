WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
, ActorRoles AS (
    SELECT 
        a.id AS actor_id,
        an.name AS actor_name,
        c.movie_id,
        r.role
    FROM 
        cast_info c
    JOIN 
        aka_name an ON c.person_id = an.person_id
    JOIN 
        role_type r ON c.role_id = r.id
)
, MovieKeywords AS (
    SELECT 
        mk.movie_id,
        array_agg(k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.level,
    ar.actor_name,
    CASE 
        WHEN COALESCE(mk.keywords, '{}') = '{}' THEN 'No Keywords'
        ELSE string_agg(mk.keywords, ', ')
    END AS keywords,
    COUNT(DISTINCT ar.actor_id) OVER (PARTITION BY mh.movie_id) AS actor_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorRoles ar ON mh.movie_id = ar.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.level < 3 
    AND ar.actor_name IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, mh.level, ar.actor_name, mk.keywords
ORDER BY 
    mh.level, mh.movie_id;
