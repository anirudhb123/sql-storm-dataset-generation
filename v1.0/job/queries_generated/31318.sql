WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.title,
        mt.production_year,
        1 AS level,
        mt.id AS movie_id,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        at.title,
        at.production_year,
        mh.level + 1,
        at.id,
        mh.movie_id
    FROM 
        aka_title at
    JOIN 
        MovieHierarchy mh ON at.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rn
    FROM 
        MovieHierarchy mh
),
MovieKeywordCounts AS (
    SELECT 
        mt.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
),
CombinedResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.level,
        rnk.rn,
        mkc.keyword_count
    FROM 
        RankedMovies rm
    JOIN 
        MovieKeywordCounts mkc ON rm.movie_id = mkc.movie_id
)
SELECT 
    cr.title,
    cr.production_year,
    cr.level,
    cr.rn,
    COALESCE(cr.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN cr.keyword_count IS NULL THEN 'No Keywords'
        WHEN cr.keyword_count > 5 THEN 'High Keyword Count'
        ELSE 'Moderate Keyword Count'
    END AS keyword_status
FROM 
    CombinedResults cr
WHERE 
    cr.level = 1 
    OR (cr.rn <= 5 AND cr.level > 1)
ORDER BY 
    cr.production_year DESC, cr.level, cr.rn;
