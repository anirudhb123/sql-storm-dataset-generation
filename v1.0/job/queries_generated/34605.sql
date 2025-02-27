WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all titles with their immediate children
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        1 AS level
    FROM 
        title t
    WHERE 
        t.episode_of_id IS NOT NULL

    UNION ALL

    -- Recursive case: Join to find all episodes of the current title being processed
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        mh.level + 1
    FROM 
        title t
    JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
AggregateCast AS (
    -- Aggregate the role types for each movie
    SELECT 
        cc.movie_id,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info cc
    JOIN 
        role_type rt ON cc.role_id = rt.id
    GROUP BY 
        cc.movie_id
),
MovieInfo AS (
    -- Collect information about movie titles and their associated information
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(mk.keyword, 'No Keywords') AS keywords,
        COALESCE(ma.roles, 'No Roles') AS roles,
        COUNT(mi.id) AS info_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        AggregateCast ma ON t.id = ma.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.id, t.title, mk.keyword, ma.roles
),
RankedMovies AS (
    -- Rank movies based on the number of information entries and levels from hierarchy
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        m.keywords,
        m.roles,
        m.info_count,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY m.info_count DESC) AS rank_within_level
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieInfo m ON mh.movie_id = m.movie_id
)
-- Final selection of distinct titles and their corresponding ranks and roles
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.keywords,
    rm.roles,
    rm.rank_within_level
FROM 
    RankedMovies rm
WHERE 
    rm.rank_within_level <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.rank_within_level;
