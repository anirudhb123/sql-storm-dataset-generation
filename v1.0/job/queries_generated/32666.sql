WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS hierarchy_level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  -- Start with movies from 2000 onwards

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        mh.production_year,
        mh.hierarchy_level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title m ON m.episode_of_id = mh.movie_id  -- Join to find episodes
),
ActorStats AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN
        aka_name a ON a.person_id = ci.person_id
    GROUP BY 
        ci.person_id
),
TitleInfo AS (
    SELECT
        t.id AS title_id,
        t.title,
        k.keyword,
        t.production_year
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2010
),
Summary AS (
    SELECT
        mv.movie_id,
        mv.title,
        mv.production_year,
        COALESCE(STATS.movie_count, 0) AS actor_count,
        COALESCE(ti.keyword, 'No Keywords') AS keywords
    FROM 
        MovieHierarchy mv
    LEFT JOIN 
        ActorStats STATS ON STATS.movie_count > 0  -- Join ActorStats for active actors
    LEFT JOIN 
        TitleInfo ti ON ti.title_id = mv.movie_id
)
SELECT 
    s.title AS "Movie Title",
    s.production_year AS "Year",
    s.actor_count AS "Actor Count",
    s.keywords AS "Keywords",
    ROW_NUMBER() OVER (PARTITION BY s.production_year ORDER BY s.actor_count DESC) AS "Rank"
FROM 
    Summary s
WHERE 
    s.actor_count > 0  -- Filter to only include movies with actors
ORDER BY 
    s.production_year DESC, s.actor_count DESC;  -- Sort by year and actor count
