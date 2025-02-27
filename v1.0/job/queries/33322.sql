WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        CAST(NULL AS text) AS parent_title,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.title AS parent_title,
        mh.level + 1
    FROM 
        aka_title t
    JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),

MovieWithKeywords AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.kind_id
),

CastStatistics AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        COUNT(DISTINCT c.role_id) AS unique_roles
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
)

SELECT 
    mwk.movie_id,
    mwk.title,
    mwk.production_year,
    mwk.keywords,
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.unique_roles, 0) AS unique_roles,
    RANK() OVER (ORDER BY mwk.production_year DESC) AS year_rank,
    RANK() OVER (PARTITION BY mwk.kind_id ORDER BY mwk.title) AS kind_rank
FROM 
    MovieWithKeywords mwk
LEFT JOIN 
    CastStatistics cs ON mwk.movie_id = cs.movie_id
WHERE 
    mwk.production_year >= 2000
ORDER BY 
    mwk.production_year DESC, mwk.title;

