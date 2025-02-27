WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Starting from the year 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
, CastDetails AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ci.nr_order,
        ri.role AS role_name,
        RANK() OVER (PARTITION BY at.id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    JOIN 
        role_type ri ON ci.role_id = ri.id
)
, MovieInfo AS (
    SELECT 
        mh.movie_id,
        mh.title,
        COALESCE(MAX(md.info), 'N/A') AS additional_info
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        movie_info md ON mh.movie_id = md.movie_id
    GROUP BY 
        mh.movie_id, mh.title
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.parent_id,
    COALESCE(c.actor_name, 'No Cast') AS actor_name,
    md.additional_info,
    cd.role_name,
    cd.production_year,
    CD.role_rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastDetails cd ON mh.movie_id = cd.movie_title
LEFT JOIN 
    MovieInfo md ON mh.movie_id = md.movie_id
WHERE 
    mh.level <= 2  -- Limiting depth of the hierarchy
ORDER BY 
    mh.production_year DESC,
    mh.title,
    cd.role_rank
LIMIT 100;
