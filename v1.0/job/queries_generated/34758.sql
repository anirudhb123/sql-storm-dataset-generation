WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastDetails AS (
    SELECT 
        ci.id AS cast_id,
        ci.movie_id,
        CONCAT(a.name, ' as ', rt.role) AS cast_name,
        a.id AS person_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS cast_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT mi.info) AS additional_info
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('rating', 'summary'))
    GROUP BY 
        m.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cd.cast_name, 'No Cast') AS cast_name,
    COALESCE(mi.keywords, 'No Keywords') AS keywords,
    COALESCE(mi.additional_info, 'No Additional Info') AS additional_info,
    COUNT(cd.cast_id) OVER (PARTITION BY mh.movie_id) AS total_cast,
    mh.level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.production_year >= 2000
ORDER BY 
    mh.level, mh.production_year DESC, total_cast DESC;
