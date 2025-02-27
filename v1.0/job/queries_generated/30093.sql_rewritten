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
        ak.title,
        ak.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title ak ON ml.linked_movie_id = ak.id
    WHERE 
        mh.depth < 3 
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
MovieInfo AS (
    SELECT 
        ah.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS movie_info,
        MAX(CASE WHEN it.info = 'Rating' THEN mi.info END) AS rating
    FROM 
        complete_cast ah
    LEFT JOIN 
        movie_info mi ON ah.movie_id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        ah.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ci.actor_name,
    ci.role_name,
    mi.movie_info,
    mi.rating
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastDetails ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE 
    ci.actor_order IS NOT NULL 
AND 
    (mi.rating IS NOT NULL OR (SELECT COUNT(*) FROM movie_info WHERE movie_id = mh.movie_id) = 0) 
ORDER BY 
    mh.production_year DESC, mh.title, ci.actor_order;