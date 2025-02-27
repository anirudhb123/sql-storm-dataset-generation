WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),
CastByRole AS (
    SELECT 
        ci.movie_id,
        ri.role AS person_role,
        COUNT(DISTINCT ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type ri ON ci.role_id = ri.id
    GROUP BY 
        ci.movie_id, ri.role
),
GenreCount AS (
    SELECT 
        mt.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS genre_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    cb.person_role,
    cb.role_count,
    COALESCE(gc.genre_count, 0) AS genre_count,
    CASE 
        WHEN mh.level > 1 THEN 'Episode' 
        ELSE 'Movie' 
    END AS type_of_entry
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastByRole cb ON mh.movie_id = cb.movie_id
LEFT JOIN 
    GenreCount gc ON mh.movie_id = gc.movie_id
ORDER BY 
    mh.production_year DESC,
    mh.title ASC;
