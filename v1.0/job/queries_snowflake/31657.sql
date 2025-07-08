
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS hierarchy_level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = 2023

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.hierarchy_level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
), 
CastRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS lead_actors
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        ci.nr_order < 4  
    GROUP BY 
        ci.movie_id
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
) 
SELECT 
    mh.movie_id,
    mh.movie_title,
    COALESCE(cr.total_cast, 0) AS total_cast,
    COALESCE(cr.lead_actors, 'None') AS lead_actors,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    mh.hierarchy_level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastRoles cr ON mh.movie_id = cr.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
ORDER BY 
    mh.hierarchy_level, mh.movie_title;
