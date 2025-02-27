WITH Recursive MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        CAST(NULL AS VARCHAR) AS parent_movie_title
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.title AS parent_movie_title
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
MovieCast AS (
    SELECT 
        DISTINCT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
TitleInfo AS (
    SELECT 
        t.title,
        t.production_year,
        CASE 
            WHEN t.production_year IS NULL THEN 'Unknown Year'
            ELSE t.production_year::TEXT
        END AS display_year,
        k.keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
RankedTitles AS (
    SELECT 
        ti.title,
        ti.display_year,
        mh.parent_movie_title,
        mc.actor_count,
        ROW_NUMBER() OVER (PARTITION BY ti.production_year ORDER BY mc.actor_count DESC) AS rank_within_year
    FROM 
        TitleInfo ti
    LEFT JOIN 
        MovieHierarchy mh ON ti.title = mh.title
    LEFT JOIN 
        MovieCast mc ON ti.movie_id = mc.movie_id
)
SELECT 
    rt.title,
    rt.display_year,
    rt.parent_movie_title,
    COALESCE(rt.actor_count, 0) AS actor_count,
    CASE 
        WHEN rt.rank_within_year IS NULL THEN 'Not Ranked' 
        ELSE rt.rank_within_year::TEXT 
    END AS rank_desc
FROM 
    RankedTitles rt
WHERE 
    (rt.parent_movie_title IS NULL OR rt.actor_count > 5)
    AND rt.production_year IS NOT NULL
ORDER BY 
    rt.display_year DESC, rt.actor_count DESC;
