WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.Kind_id,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL  -- Starting point for the hierarchy

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id  -- Join on episode_of_id
),

KeywordUsage AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
),

FullCast AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),

MoviesWithKeywords AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        fu.total_cast,
        ku.keyword,
        ku.keyword_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        FullCast fu ON mh.movie_id = fu.movie_id
    LEFT JOIN 
        KeywordUsage ku ON mh.movie_id = ku.movie_id
),

RankedMovies AS (
    SELECT 
        mwk.title,
        mwk.production_year,
        mwk.total_cast,
        mwk.keyword,
        mwk.keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mwk.production_year ORDER BY mwk.total_cast DESC) AS rank_per_year
    FROM 
        MoviesWithKeywords mwk
)

SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.keyword,
    rm.keyword_count,
    CASE 
        WHEN rm.keyword_count IS NULL THEN 'No Keywords'
        ELSE 'Has Keywords'
    END AS keyword_status
FROM 
    RankedMovies rm
WHERE 
    rm.rank_per_year <= 5  -- Top 5 movies per year
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC;
