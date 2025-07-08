
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL 

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id 
),
ActorTitles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_order,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_actors
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.role_id IN (SELECT id FROM role_type WHERE role LIKE '%Lead%')
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COUNT(k.keyword) AS keyword_count,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(at.actor_name, 'No Actors') AS actor_name,
    at.actor_order,
    at.total_actors,
    mi.keyword_count,
    mi.keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorTitles at ON mh.movie_id = at.movie_id
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
ORDER BY 
    mh.production_year DESC, 
    mh.level, 
    at.actor_order
LIMIT 100;
