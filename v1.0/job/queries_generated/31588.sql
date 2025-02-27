WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
CastRoleStats AS (
    SELECT 
        c.movie_id,
        c.role_id,
        r.role AS role_name,
        COUNT(*) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY COUNT(*) DESC) AS rank
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, c.role_id, r.role
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        MAX(mi.info) AS tagline,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON mi.movie_id = m.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'tagline')
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        m.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(mis.tagline, 'No tagline available') AS tagline,
    mis.keywords,
    crs.role_name,
    crs.cast_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieInfo mis ON mh.movie_id = mis.movie_id
LEFT JOIN 
    CastRoleStats crs ON mh.movie_id = crs.movie_id AND crs.rank = 1
ORDER BY 
    mh.production_year DESC, 
    mh.title;
