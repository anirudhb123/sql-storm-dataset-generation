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
        l.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link l
    JOIN 
        aka_title m ON l.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON l.movie_id = mh.movie_id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(*) OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        MIN(mi.info) AS first_info,
        MAX(mi.info) AS last_info,
        COUNT(DISTINCT mi.info_type_id) AS distinct_info_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id, m.title
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT a.actor_name) AS actor_count,
    SUM(CASE WHEN ar.role_count > 1 THEN 1 ELSE 0 END) AS multiple_role_actors,
    COALESCE(m.first_info, 'No Info') AS first_info,
    COALESCE(m.last_info, 'No Info') AS last_info,
    m.distinct_info_count,
    STRING_AGG(DISTINCT ar.role_name, ', ') AS roles
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorRoles ar ON mh.movie_id = ar.movie_id
LEFT JOIN 
    MovieInfo m ON mh.movie_id = m.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, m.first_info, m.last_info, m.distinct_info_count
HAVING 
    COUNT(DISTINCT a.actor_name) > 5
ORDER BY 
    mh.production_year DESC, mh.title;
