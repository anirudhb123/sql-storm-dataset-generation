WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.depth + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
),

ActorRoles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        r.role AS character_role,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info AS ci
    JOIN 
        role_type AS r ON ci.role_id = r.id
),

MovieInfoFilters AS (
    SELECT 
        m.id AS movie_id,
        MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS director,
        MAX(CASE WHEN mi.info_type_id = 2 THEN mi.info END) AS writer,
        MAX(CASE WHEN mi.info_type_id = 3 THEN mi.info END) AS producer
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_info AS mi ON m.id = mi.movie_id
    GROUP BY 
        m.id
)

SELECT 
    mh.title,
    mh.production_year,
    mh.depth,
    ar.character_role,
    mif.director,
    mif.writer,
    mif.producer
FROM 
    MovieHierarchy AS mh
LEFT JOIN 
    ActorRoles AS ar ON mh.movie_id = ar.movie_id 
LEFT JOIN 
    MovieInfoFilters AS mif ON mh.movie_id = mif.movie_id
WHERE 
    (mif.director IS NOT NULL OR mif.writer IS NOT NULL OR mif.producer IS NOT NULL)
    AND (mh.kind_id IN (1, 2) OR mh.production_year < 2010)
ORDER BY 
    mh.production_year DESC, mh.title, ar.role_rank;
