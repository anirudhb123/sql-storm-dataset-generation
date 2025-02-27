WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.season_nr,
        t.episode_nr,
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL -- Top-level movies only

    UNION ALL

    SELECT 
        t.id,
        t.title,
        t.production_year,
        t.kind_id,
        t.season_nr,
        t.episode_nr,
        h.depth + 1
    FROM 
        aka_title t
    JOIN 
        MovieHierarchy h ON t.episode_of_id = h.movie_id
),
CastCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        COALESCE(cc.cast_count, 0) AS cast_count,
        mh.depth
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastCounts cc ON mh.movie_id = cc.movie_id
),
TitleKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    kt.keywords,
    md.cast_count,
    CASE 
        WHEN md.kind_id IS NOT NULL THEN 'Screen' 
        ELSE 'Unknown' 
    END AS display_type,
    ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS rank_within_year
FROM 
    MovieDetails md
LEFT JOIN 
    TitleKeywords kt ON md.movie_id = kt.movie_id
WHERE 
    md.production_year >= 2000 -- Filter for movies in the 21st century
    AND (md.depth = 1 OR md.cast_count > 5) -- Only top-level movies or those with significant cast
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
