WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL  -- Base case: Top-level movies
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id  -- Recursion: Finding episodes of a movie
),
MovieWithInfo AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT p.info, ', ') AS person_infos
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id 
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        person_info p ON ci.person_id = p.person_id 
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
MoviesWithKeywords AS (
    SELECT 
        mwi.movie_id,
        mwi.title,
        mwi.production_year,
        mwi.total_cast,
        mwi.person_infos,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        MovieWithInfo mwi
    LEFT JOIN 
        movie_keyword mk ON mwi.movie_id = mk.movie_id
    GROUP BY 
        mwi.movie_id, mwi.title, mwi.production_year, mwi.total_cast, mwi.person_infos
)
SELECT 
    mwk.movie_id,
    mwk.title,
    mwk.production_year,
    mwk.total_cast,
    mwk.person_infos,
    CASE 
        WHEN mwk.keyword_count > 5 THEN 'High'
        WHEN mwk.keyword_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS keyword_category
FROM 
    MoviesWithKeywords mwk
WHERE 
    mwk.production_year >= 2000  -- Filter for movies from the year 2000 onward
ORDER BY 
    mwk.production_year DESC, 
    mwk.total_cast DESC
LIMIT 10;  -- Limit the results to top 10 movies

