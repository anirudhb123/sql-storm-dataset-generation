WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        id,
        title,
        production_year,
        episode_of_id,
        season_nr,
        episode_nr,
        1 AS level
    FROM 
        aka_title
    WHERE 
        episode_of_id IS NULL

    UNION ALL

    SELECT 
        a.id,
        a.title,
        a.production_year,
        a.episode_of_id,
        a.season_nr,
        a.episode_nr,
        mh.level + 1
    FROM 
        aka_title a
    INNER JOIN 
        MovieHierarchy mh ON a.episode_of_id = mh.id
),
GenreStatistics AS (
    SELECT 
        kt.kind AS genre,
        COUNT(DISTINCT mt.id) AS movie_count,
        AVG(mt.production_year) AS avg_year
    FROM 
        kind_type kt
    LEFT JOIN 
        aka_title mt ON mt.kind_id = kt.id
    GROUP BY 
        kt.kind
),
ActorPerformance AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_active,
        MAX(mti.production_year) AS last_active_year,
        STRING_AGG(mt.title, ', ') AS movies_list
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ci.person_id = ak.person_id
    JOIN 
        aka_title mt ON mt.id = ci.movie_id
    LEFT JOIN 
        movie_info mti ON mti.movie_id = mt.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
),
InfoPerTitle AS (
    SELECT 
        mt.title,
        COUNT(DISTINCT pi.info_type_id) AS unique_info_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info mi ON mi.movie_id = mt.id
    LEFT JOIN 
        person_info pi ON pi.person_id = mi.info_type_id
    GROUP BY 
        mt.title
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    gs.genre,
    gs.movie_count,
    gs.avg_year,
    ap.actor_name,
    ap.movies_active,
    ap.last_active_year,
    ipt.unique_info_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    GenreStatistics gs ON mh.id = gs.movie_count
LEFT JOIN 
    ActorPerformance ap ON ap.movies_active > 5
LEFT JOIN 
    InfoPerTitle ipt ON ipt.title = mh.title
WHERE 
    mh.production_year >= 2000
    AND (gs.avg_year > 2010 OR gs.genre IS NULL)
ORDER BY 
    mh.production_year DESC, gs.movie_count DESC;
