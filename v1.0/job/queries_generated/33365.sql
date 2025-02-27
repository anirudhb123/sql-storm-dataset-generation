WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level,
        CAST(t.title AS VARCHAR(255)) AS full_path
    FROM 
        aka_title t 
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1,
        CONCAT(mh.full_path, ' -> ', t.title) AS full_path
    FROM 
        aka_title t
    INNER JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
CastWithRoles AS (
    SELECT 
        ci.movie_id,
        r.role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MoviesWithDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ck.role, 'Unknown') AS role,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        mh.full_path,
        ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY ck.role) AS role_order
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastWithRoles ck ON mh.movie_id = ck.movie_id
    LEFT JOIN 
        MovieKeywords mk ON mh.movie_id = mk.movie_id
)
SELECT 
    mwd.title,
    mwd.production_year,
    mwd.role,
    mwd.keywords,
    mwd.full_path
FROM 
    MoviesWithDetails mwd
WHERE 
    mwd.production_year >= 2000 
    AND mwd.role_order = 1
ORDER BY 
    mwd.production_year DESC, mwd.title;

-- Result includes movie titles, their production years, roles of the main cast, 
-- and keywords associated with each movie, sorted by production year.
