
WITH RECURSIVE CTE_MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        ARRAY_CONSTRUCT(mt.id) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        ep.id AS movie_id,
        ep.title,
        ep.production_year,
        mh.level + 1,
        ARRAY_CAT(mh.path, ARRAY_CONSTRUCT(ep.id)) AS path
    FROM 
        aka_title ep
    JOIN 
        CTE_MovieHierarchy mh ON ep.episode_of_id = mh.movie_id
),

MovieActors AS (
    SELECT 
        at.id AS movie_id,
        ac.person_id,
        ak.name,
        ROW_NUMBER() OVER(PARTITION BY at.id ORDER BY ac.nr_order) AS actor_order
    FROM 
        aka_title at
    JOIN 
        cast_info ac ON at.id = ac.movie_id
    JOIN 
        aka_name ak ON ac.person_id = ak.person_id
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
),

AggregatedMovieData AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(SUM(mk.keyword_count), 0) AS total_keywords,
        LISTAGG(DISTINCT ma.name, ', ') AS actors,
        COUNT(DISTINCT ma.person_id) AS actor_count
    FROM 
        CTE_MovieHierarchy mh
    LEFT JOIN 
        MovieKeywords mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        MovieActors ma ON mh.movie_id = ma.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)

SELECT 
    amd.title,
    amd.production_year,
    amd.total_keywords,
    amd.actors,
    amd.actor_count,
    CASE 
        WHEN amd.actor_count > 10 THEN 'Ensemble Cast'
        WHEN amd.actor_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    CASE 
        WHEN mh.level IS NULL THEN 'Standalone Movie'
        ELSE 'Part of a Series'
    END AS movie_type
FROM 
    AggregatedMovieData amd
LEFT JOIN 
    CTE_MovieHierarchy mh ON amd.movie_id = mh.movie_id
ORDER BY 
    amd.total_keywords DESC, 
    amd.actor_count DESC;
