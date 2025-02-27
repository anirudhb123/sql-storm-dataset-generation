
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL AS parent_id
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        ms.id AS movie_id,
        ms.title,
        ms.production_year,
        mh.level + 1,
        mh.movie_id
    FROM aka_title ms
    JOIN MovieHierarchy mh ON ms.episode_of_id = mh.movie_id
),
AggregatedRoles AS (
    SELECT
        ci.movie_id,
        rt.role AS role_name,
        COUNT(ci.id) AS num_cast
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id, rt.role
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ARRAY_AGG(DISTINCT ar.role_name) AS roles,
        MAX(ar.num_cast) AS max_cast
    FROM MovieHierarchy mh
    LEFT JOIN AggregatedRoles ar ON mh.movie_id = ar.movie_id
    WHERE mh.production_year BETWEEN 2000 AND 2023
    GROUP BY mh.movie_id, mh.title, mh.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.roles,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    fm.max_cast,
    COUNT(ci.id) AS total_cast_members
FROM FilteredMovies fm
LEFT JOIN cast_info ci ON fm.movie_id = ci.movie_id
LEFT JOIN MovieKeywords mk ON fm.movie_id = mk.movie_id
GROUP BY 
    fm.title, 
    fm.production_year, 
    fm.roles, 
    mk.keywords, 
    fm.max_cast
ORDER BY 
    fm.production_year DESC, 
    fm.max_cast DESC, 
    fm.title;
