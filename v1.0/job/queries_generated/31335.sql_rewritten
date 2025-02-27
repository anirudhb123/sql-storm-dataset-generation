WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level,
        m.production_year
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        mh.level + 1,
        m.production_year
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'episode')
),

CastWithRoles AS (
    SELECT 
        c.movie_id,
        COUNT(*) AS cast_count,
        MAX(r.role) AS lead_role
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),

TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        c.cast_count,
        c.lead_role,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY c.cast_count DESC) AS rank_in_year
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastWithRoles c ON mh.movie_id = c.movie_id
    WHERE 
        mh.production_year IS NOT NULL
)

SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.lead_role
FROM 
    TopMovies tm
WHERE 
    tm.rank_in_year <= 5  
ORDER BY 
    tm.production_year, 
    tm.rank_in_year;