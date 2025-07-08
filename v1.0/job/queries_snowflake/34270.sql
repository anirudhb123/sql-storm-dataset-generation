
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
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieInfoCTE AS (
    SELECT 
        mi.movie_id,
        LISTAGG(mi.info, '; ') WITHIN GROUP (ORDER BY mi.info) AS details
    FROM 
        movie_info mi
    WHERE 
        mi.info IS NOT NULL
    GROUP BY 
        mi.movie_id
),
MoviesWithDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        LISTAGG(DISTINCT mi.details, ', ') WITHIN GROUP (ORDER BY mi.movie_id) AS movie_details,
        COUNT(cd.actor_name) AS actor_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieInfoCTE mi ON mh.movie_id = mi.movie_id
    LEFT JOIN 
        CastDetails cd ON mh.movie_id = cd.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    mw.title,
    mw.production_year,
    mw.movie_details,
    mw.actor_count,
    COALESCE(mw.movie_details, '<No Details>') AS display_details
FROM 
    MoviesWithDetails mw
WHERE 
    mw.actor_count > 0
ORDER BY 
    mw.production_year DESC, mw.title ASC
LIMIT 50;
