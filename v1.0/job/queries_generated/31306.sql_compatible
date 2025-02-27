
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id, 
        mt.title, 
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.level < 2  
),
TopActors AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY COUNT(ci.person_id) DESC) AS actor_rank
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mi.info, 'No Info') AS additional_info,
        t.kind AS movie_kind,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        kind_type t ON m.kind_id = t.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id, mi.info, t.kind
)
SELECT 
    mh.title AS movie_title,
    mh.level,
    ta.actor_name,
    mi.additional_info,
    mi.movie_kind,
    mi.keyword_count
FROM 
    MovieHierarchy mh
JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    TopActors ta ON mh.movie_id = ta.movie_id AND ta.actor_rank = 1  
WHERE 
    mi.keyword_count > 0  
ORDER BY 
    mh.level, mi.keyword_count DESC;
