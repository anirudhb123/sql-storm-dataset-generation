
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(m.title AS VARCHAR) AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || m.title AS VARCHAR) AS path
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        m.production_year >= 2000
    AND 
        mh.level < 5
),
MovieCast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MAX(CASE WHEN r.role = 'Lead' THEN 1 ELSE 0 END) AS has_lead
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT CASE WHEN it.info = 'Genre' THEN mi.info END, ', ') AS genres,
        STRING_AGG(DISTINCT CASE WHEN it.info = 'Language' THEN mi.info END, ', ') AS languages
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mc.actors,
    mc.actor_count,
    mc.has_lead,
    mi.genres,
    mi.languages
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieCast mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE 
    (mc.actor_count > 3 OR mh.level = 1) 
AND 
    (mc.has_lead = 1 OR mi.genres IS NOT NULL)
ORDER BY 
    mh.production_year DESC, 
    mc.actor_count DESC;
