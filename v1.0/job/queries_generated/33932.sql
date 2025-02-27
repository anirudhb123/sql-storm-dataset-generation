WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        child.title,
        child.production_year,
        parent.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title child ON ml.linked_movie_id = child.id
    JOIN 
        MovieHierarchy parent ON ml.movie_id = parent.movie_id
),

RankedActors AS (
    SELECT 
        ca.person_id,
        ak.name,
        RANK() OVER (PARTITION BY ca.movie_id ORDER BY ca.nr_order) AS actor_rank
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
),

MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        SUM(CASE 
            WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office') 
            THEN CAST(mi.info AS INTEGER)
            ELSE 0 
        END) AS total_box_office,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id, m.title
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ma.name AS top_actor,
    mi.total_box_office,
    mi.keyword_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    RankedActors ma ON mh.movie_id = ma.movie_id AND ma.actor_rank = 1
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE 
    mi.total_box_office IS NOT NULL
ORDER BY 
    mh.production_year DESC,
    mi.total_box_office DESC;
