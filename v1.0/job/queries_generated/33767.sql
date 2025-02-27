WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1 AS level
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_role_id,
        ct.kind AS role_type,
        COUNT(ci.person_id) AS total_cast
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        ci.movie_id, ci.person_role_id, ct.kind
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
        STRING_AGG(mii.info, '; ') AS details
    FROM 
        movie_info mi
    JOIN 
        movie_info_idx mii ON mi.id = mii.movie_id
    GROUP BY 
        mi.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.kind_id,
    COALESCE(cr.role_type, 'Cast Unknown') AS role_type,
    COALESCE(cr.total_cast, 0) AS total_cast,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mi.details, 'No Info Available') AS movie_details,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS row_num
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastRoles cr ON mh.movie_id = cr.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.level <= 2   -- Limit level for hierarchical representation
ORDER BY 
    mh.production_year, 
    mh.title;
