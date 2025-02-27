WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        NULL::integer AS parent_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  -- Starting point: top-level movies

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        e.kind_id,
        mh.movie_id AS parent_id,
        mh.depth + 1
    FROM 
        aka_title e
    INNER JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id  -- Recursive join
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rank,
        COALESCE(keyword.keyword, 'No Keyword') AS keyword  -- Handling NULL logic
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ON mk.keyword_id = keyword.id
),
CastInfo AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
EnrichedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank,
        COALESCE(ci.total_cast, 0) AS total_cast  -- Handling NULL logic
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastInfo ci ON rm.movie_id = ci.movie_id
)
SELECT 
    em.movie_id,
    em.title,
    em.production_year,
    em.rank,
    em.total_cast,
    (em.total_cast * 1.0 / NULLIF(COUNT(*) OVER (PARTITION BY em.production_year), 0)) AS cast_ratio,  -- Cast ratio calculation
    CASE 
        WHEN em.total_cast > 0 THEN 'Has Cast'
        WHEN em.total_cast IS NULL THEN 'No Data'
        ELSE 'No Cast'
    END AS cast_status,  -- Status based on cast
    STRING_AGG(a.name, ', ' ORDER BY a.name) AS actors_names  -- Aggregating actor names
FROM 
    EnrichedMovies em
LEFT JOIN 
    complete_cast cc ON em.movie_id = cc.movie_id
LEFT JOIN 
    aka_name a ON cc.subject_id = a.person_id
GROUP BY 
    em.movie_id, em.title, em.production_year, em.rank, em.total_cast
ORDER BY 
    em.production_year DESC, em.title ASC;  -- Ordering by production year and title
