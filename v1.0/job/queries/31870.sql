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
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),
CastAggregates AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count,
        STRING_AGG(CONCAT_WS(' ', ak.name, ak.surname_pcode), ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ca.actor_count,
        ca.actor_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastAggregates ca ON mh.movie_id = ca.movie_id
),
QualifiedTitles AS (
    SELECT 
        f.title,
        f.production_year,
        f.actor_count,
        ROW_NUMBER() OVER (PARTITION BY f.production_year ORDER BY f.actor_count DESC) AS rn
    FROM 
        FilteredMovies f
    WHERE 
        f.actor_count IS NOT NULL 
        AND f.production_year > 2000
        AND f.title NOT LIKE '%Unrated%'
)
SELECT 
    qt.title,
    qt.production_year,
    qt.actor_count
FROM 
    QualifiedTitles qt
WHERE 
    qt.rn <= 5
ORDER BY 
    qt.production_year DESC, 
    qt.actor_count DESC;