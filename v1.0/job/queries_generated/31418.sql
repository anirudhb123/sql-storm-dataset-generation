WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
  
    UNION ALL 

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),

RankedActors AS (
    SELECT 
        ci.person_id,
        count(ci.movie_id) AS movie_count,
        RANK() OVER (PARTITION BY ci.person_id ORDER BY count(ci.movie_id) DESC) AS actor_rank
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),

EnhancedTitles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        COALESCE(MAX(CASE WHEN minfo.info_type_id = 1 THEN minfo.info END), 'Unknown') AS genre,
        COALESCE(MAX(CASE WHEN minfo.info_type_id = 2 THEN minfo.info END), 'No Info') AS summary
    FROM 
        aka_title a
    LEFT JOIN 
        movie_info minfo ON a.id = minfo.movie_id
    GROUP BY 
        a.id
)

SELECT 
    mh.title,
    mh.production_year,
    coalesce(b.actor_name, 'Unknown Actor') AS top_actor,
    r.movie_count,
    mh.level,
    e.genre,
    e.summary
FROM 
    MovieHierarchy mh
LEFT JOIN 
    (SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name
     FROM 
        aka_name ak
     JOIN 
        RankedActors ra ON ak.person_id = ra.person_id
     WHERE 
        ra.actor_rank = 1) b ON mh.movie_id IN (SELECT movie_id FROM cast_info ci WHERE ci.person_id = b.actor_id)
LEFT JOIN 
    RankedActors r ON b.actor_id = r.person_id
JOIN 
    EnhancedTitles e ON mh.movie_id = e.title_id
WHERE 
    mh.production_year BETWEEN 2000 AND 2020
    AND (e.genre LIKE '%Drama%' OR e.genre LIKE '%Action%')
ORDER BY 
    mh.production_year DESC, 
    movie_count DESC;
