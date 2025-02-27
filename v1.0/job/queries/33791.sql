
WITH RECURSIVE MovieHierarchy AS (
    
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        0 AS level
    FROM 
        title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id,
        t.title,
        t.production_year,
        t.episode_of_id,
        mh.level + 1
    FROM 
        title t
    INNER JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
StarCast AS (
    
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    
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
    mh.title AS movie_title,
    mh.production_year,
    COALESCE(sc.cast_count, 0) AS total_cast,
    COALESCE(mk.keywords, 'No Keywords') AS associated_keywords,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COALESCE(sc.cast_count, 0) DESC) AS rank_by_cast_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    StarCast sc ON mh.movie_id = sc.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year >= 2000
    AND mh.level = 0
GROUP BY 
    mh.title, mh.production_year, sc.cast_count, mk.keywords
ORDER BY 
    mh.production_year DESC,
    rank_by_cast_count ASC;
