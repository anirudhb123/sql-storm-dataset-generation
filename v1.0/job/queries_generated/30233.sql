WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        mh.level + 1
    FROM 
        aka_title t
    JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
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
    WHERE 
        a.name IS NOT NULL 
        AND c.note IS NULL
),

MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT c.actor_rank) AS actor_count,
        STRING_AGG(DISTINCT cd.actor_name, ', ') AS actor_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastDetails cd ON mh.movie_id = cd.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),

HighRatedMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(mi.info, 'N/A') AS rating
    FROM 
        MovieStats m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating' LIMIT 1)
    WHERE 
        m.actor_count > 1 
        AND (m.production_year IS NOT NULL OR m.production_year >= 2000)
)

SELECT 
    m.title,
    m.production_year,
    m.actor_count,
    m.actor_names,
    COALESCE(h.rating, 'No Rating') AS movie_rating
FROM 
    MovieStats m
LEFT JOIN 
    HighRatedMovies h ON m.movie_id = h.movie_id
ORDER BY 
    m.actor_count DESC, 
    m.production_year DESC;
