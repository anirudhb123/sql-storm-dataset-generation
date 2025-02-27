WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 1 -- Assume '1' is for movies

    UNION ALL

    SELECT 
        mv.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        mh.movie_id AS parent_movie_id
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        m.kind_id = 1
),
CastAndInfo AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) ELSE NULL END) AS avg_info_length
    FROM 
        cast_info ci
    JOIN 
        movie_info mi ON ci.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id IN (1, 2) -- Assuming '1' for synopsis and '2' for reviews
    GROUP BY 
        ci.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cai.cast_count,
        cai.avg_info_length,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY cai.cast_count DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastAndInfo cai ON mh.movie_id = cai.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    COALESCE(rm.cast_count, 0) AS cast_count,
    COALESCE(rm.avg_info_length, 0) AS avg_info_length,
    CASE 
        WHEN rm.rank IS NULL THEN 'No Data'
        WHEN rm.rank <= 5 THEN 'Top 5'
        ELSE 'Others'
    END AS rank_category
FROM 
    RankedMovies rm
ORDER BY 
    rm.production_year DESC, 
    rm.rank;

-- Additional metrics or summaries based on movie information.
SELECT 
    COUNT(*) AS total_movies,
    AVG(cast_count) AS average_cast_size
FROM 
    CastAndInfo;
