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
        h.level + 1
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy h ON m.episode_of_id = h.movie_id
),
CastRanked AS (
    SELECT 
        ci.movie_id,
        ca.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ca ON ci.person_id = ca.person_id
),
MovieKeywordCTE AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mi.info, 'No additional info') AS additional_info,
        COALESCE(CAST(MI.note AS TEXT), 'No notes') AS note
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cr.actor_name, 'No actors listed') AS actor_name,
    COUNT(DISTINCT mk.keyword) AS total_keywords,
    mi.additional_info,
    mi.note
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastRanked cr ON mh.movie_id = cr.movie_id AND cr.actor_order = 1
LEFT JOIN 
    MovieKeywordCTE mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.production_year >= 2000
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, cr.actor_name, mi.additional_info, mi.note
ORDER BY 
    mh.production_year DESC, total_keywords DESC;
