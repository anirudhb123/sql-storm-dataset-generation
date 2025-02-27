WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
),

RankedCast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
),

MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(k.keywords, 'No keywords') AS movie_keywords,
    COALESCE(rc.actor_name, 'Unknown') AS lead_actor,
    rc.actor_rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieKeywords k ON mh.movie_id = k.movie_id
LEFT JOIN 
    RankedCast rc ON mh.movie_id = rc.movie_id AND rc.actor_rank = 1
WHERE 
    mh.production_year BETWEEN 2000 AND 2020
ORDER BY 
    mh.production_year DESC, mh.title;

