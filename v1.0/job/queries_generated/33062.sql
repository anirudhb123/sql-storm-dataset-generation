WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')  -- Filtering for movies only
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name,
        rt.role,
        ci.nr_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ar.name) AS actor_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mi.info_details, 'No Additional Info') AS info_details
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorRoles ar ON mh.movie_id = ar.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mk.keywords, mi.info_details
HAVING 
    COUNT(DISTINCT ar.name) > 0
ORDER BY 
    mh.production_year DESC, actor_count DESC;
