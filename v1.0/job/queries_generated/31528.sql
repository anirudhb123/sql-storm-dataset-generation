WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m2.id,
        m2.title,
        m2.production_year,
        mh.level + 1
    FROM 
        aka_title m2
    JOIN 
        movie_link ml ON m2.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
, RankedActors AS (
    SELECT 
        a.person_id,
        ak.name,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY c.nr_order) AS role_order,
        COUNT(*) OVER (PARTITION BY a.person_id) AS role_count
    FROM 
        cast_info a
    JOIN 
        aka_name ak ON a.person_id = ak.person_id
    LEFT JOIN 
        complete_cast cc ON a.movie_id = cc.movie_id
)
, MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ra.name AS actor_name,
    ra.role_order,
    ra.role_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    RankedActors ra ON mh.movie_id = ra.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.level <= 2 -- limiting depth of hierarchy
ORDER BY 
    mh.production_year DESC, 
    ra.role_order;

